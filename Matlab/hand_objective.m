function err = hand_objective(params, data)
%HAND_OBJECTIVE 

pose_params = to_pose_params(params, size(data.model.bone_names,1));

vertex_positions = get_skinned_vertex_positions(data.model, pose_params);

n_corr = numel(data.correspondences);
err = zeros(3, n_corr);
for i=1:n_corr
    err(:,i) = data.points(:,i) - vertex_positions(:,data.correspondences(i));
end

end

function positions = get_skinned_vertex_positions(model, pose_params)
relatives = get_posed_relatives(model, pose_params);

absolutes = relatives_to_absolutes(relatives, model.parents);

transforms = zeros(size(absolutes));
for i=1:size(transforms,1)
    transforms(i,:,:) = squeeze(absolutes(i,:,:)) * ... 
        squeeze(model.inverse_base_transforms(i,:,:));
end

n_verts = size(model.base_positions,2);
positions = zeros(3,n_verts);
for i=1:size(transforms,1)
    positions = positions + ...
        (squeeze(transforms(i,1:3,:)) * model.base_positions) ...
        .* repmat(model.weights(i,:),3,1);
end

if model.is_mirrored
    positions(1,:) = -positions(1,:);
end

apply_global = true;
if apply_global
    positions = apply_global_transform(pose_params, positions);
end
end

function positions = apply_global_transform(pose_params, positions)
T = eye(3,4);
T(:,1:3) = angle_axis_to_rotation_matrix(pose_params(:,1)); % global rotation
T(:,1:3) = T(1:3,1:3) .* repmat(pose_params(:,2)',3,1);
T(:,4) = pose_params(:,3);

positions = T * [positions; ones(1,size(positions,2))];
end

function R = angle_axis_to_rotation_matrix(angle_axis)
n = sqrt(sum(angle_axis.^2));
if n < .0001
    R = eye(3);
    return;
end

x = angle_axis(1) / n;
y = angle_axis(2) / n;
z = angle_axis(3) / n;
  
s = sin(n);
c = cos(n);

R = [x*x + (1 - x*x)*c, x*y*(1 - c) - z*s, x*z*(1 - c) + y*s;
    x*y*(1 - c) + z*s, y*y + (1 - y*y)*c, y*z*(1 - c) - x*s;
    x*z*(1 - c) - y*s, z*y*(1 - c) + x*s, z*z + (1 - z*z)*c];
end

function absolutes = relatives_to_absolutes(relatives, parents)
absolutes = zeros(size(relatives));
for i=1:numel(parents)
    if parents(i) == 0
        absolutes(i,:,:) = relatives(i,:,:);
    else
        absolutes(i,:,:) = squeeze(absolutes(parents(i),:,:)) * ...
                squeeze(relatives(i,:,:));
    end
end
end

function relatives = get_posed_relatives(model, pose_params)
% default parametrization xzy # Flexion, Abduction, Twist
order = [1 3 2];
offset = 3;
n_bones = size(model.bone_names,1);
relatives = zeros(n_bones,4,4);

for i_bone = 1:n_bones
    T = eye(4);
    T(1:3,1:3) = euler_angles_to_rotation_matrix(pose_params(order,i_bone+offset));
    relatives(i_bone,:,:) = squeeze(model.base_relatives(i_bone,:,:)) * T;
end
end

function R = euler_angles_to_rotation_matrix(xyz)
tx = xyz(1); ty = xyz(2); tz = xyz(3);
Rx = [1,0,0; 0, cos(tx), -sin(tx); 0, sin(tx), cos(tx)];
Ry = [cos(ty), 0, sin(ty); 0, 1, 0; -sin(ty), 0, cos(ty)];
Rz = [cos(tz), -sin(tz), 0; sin(tz), cos(tz), 0; 0,0,1];
R = Rz*Ry*Rx;
end

function pose_params = to_pose_params(theta,n_bones)
% to_pose_params !!!!!!!!!!!!!!! fixed order pose_params !!!!!
%       1) global_rotation 2) scale 3) global_translation
%       4) wrist
%       5) thumb1, 6)thumb2, 7) thumb3, 8) thumb4
%       similarly: index, middle, ring, pinky
%       end) forearm

n = 3 + n_bones;
pose_params = zeros(3,n);

pose_params(:,1) = theta(1:3);
pose_params(:,2) = 1;
pose_params(:,3) = theta(4:6);

i_theta = 7;
i_pose_params = 6;
n_fingers = 5;
for finger = 1:n_fingers
    for i=[2 3 4]
        pose_params(1,i_pose_params) = theta(i_theta);
        i_theta = i_theta + 1;
        if i==2
            pose_params(2,i_pose_params) = theta(i_theta);
            i_theta = i_theta + 1;
        end
        i_pose_params = i_pose_params+1;
    end
    i_pose_params = i_pose_params+1;
end

end