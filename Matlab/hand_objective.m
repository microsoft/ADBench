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