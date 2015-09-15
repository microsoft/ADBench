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