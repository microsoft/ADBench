% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function [params, data, us] = load_hand_instance(model_dir,fn)

bones_fn = fullfile(model_dir,'bones.txt');

A=readtable(bones_fn,'Delimiter',':','ReadVariableNames',false);

bone_names = table2cell(A(:,1));
n_bones = size(bone_names,1);

parents = table2array(A(:,2)) + 1; %matlab indexing

transforms = table2array(A(:,3:18));
transforms = permute(reshape(transforms,[n_bones 4 4]), [1 3 2]);

inverse_absolute_transforms  = table2array(A(:,19:34));
inverse_absolute_transforms = permute(reshape(...
    inverse_absolute_transforms,[n_bones 4 4]),[1 3 2]);

vertices_fn = fullfile(model_dir,'vertices.txt');
A=dlmread(vertices_fn,':');

base_positions = A(:,1:3)';
n_vertices = size(A,1);

weights = zeros(n_bones,n_vertices);
for i_vert = 1:n_vertices
    for i=0:A(i_vert,9)-1
        i_bone = A(i_vert,9 + i*2 + 1) + 1; %matlab indexing
        weights(i_bone, i_vert) = A(i_vert,9 + i*2 + 2);
    end
end

triangles=dlmread(fullfile(model_dir,'triangles.txt'),':')'+1;%matlab indexing

fid = fopen(fn,'r');

n_pts = fscanf(fid,'%i',1);
n_params = fscanf(fid,'%i',1);

all = fscanf(fid,'%lf',[1+3 n_pts])';
correspondences = all(:,1) + 1; %matlab indexing
pts = all(:,2:end)';

if nargout >= 3
    us = fscanf(fid,'%lf',[2 n_pts]);
end

params = fscanf(fid,'%lf',[1 n_params]);

fclose(fid);

model = {};
model.bone_names = bone_names;
model.parents = parents;
model.base_relatives = transforms;
model.inverse_base_transforms = inverse_absolute_transforms;
model.base_positions = [base_positions; ones(1,size(base_positions,2))];
model.weights = weights;
model.triangles = triangles;
model.is_mirrored = false;

data = {};
data.model = model;
data.correspondences = correspondences;
data.points = pts;

end

