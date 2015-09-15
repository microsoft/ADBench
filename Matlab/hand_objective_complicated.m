function err = hand_objective_complicated(params, us, data)
%HAND_OBJECTIVE 

pose_params = to_pose_params(params, size(data.model.bone_names,1));

vertex_positions = get_skinned_vertex_positions(data.model, pose_params);

n_corr = numel(data.correspondences);
err = zeros(3, n_corr);
for i=1:n_corr
    verts = data.model.triangles(:,data.correspondences(i));
    u = us(:,i);
    hand_point = u(1)*vertex_positions(:,verts(1)) + ...
        u(2)*vertex_positions(:,verts(2)) + ...
        (1-sum(u))*vertex_positions(:,verts(3));
    err(:,i) = data.points(:,i) - hand_point;
end

end