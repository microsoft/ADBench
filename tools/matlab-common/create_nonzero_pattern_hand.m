function P = create_nonzero_pattern_hand(data)

weights = data.model.weights;
parents = data.model.parents;

global_params = [true(3) logical(eye(3))];

nnz = (weights(:,data.correspondences) ~= 0)';

[~,parents_order] = sort(parents,'descend');
for i=parents_order'
    if parents(i)~=0
        nnz(:,parents(i)) = nnz(:,i) | nnz(:,parents(i));
    end
end

nnz = nnz(:,2:end-1); % remove wrist and forearm
nnz(:,1:4:20)=[]; % remove thumb1, index1,...

% repeat thumb2, index2,..
n_reps = ones(1,15);
n_reps(1:3:15) = 2; 
repeat_cols = @(i) repmat(nnz(:,i), 1, n_reps(i));
nnz = cell2mat(arrayfun(repeat_cols,(1:15), 'UniformOutput', false));

% repeat rows (every point has x, y, z)
n_pts = size(data.points,2);
repeat_rows = @(i) repmat(nnz(i,:), 3, 1);
nnz = cell2mat(arrayfun(repeat_rows,(1:n_pts)', 'UniformOutput', false));

P = [repmat(global_params,n_pts,1) nnz];

end