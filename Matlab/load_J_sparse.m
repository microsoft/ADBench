function [ J ] = load_J_sparse( fn )
%LOAD_J_SPARSE Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(fn,'r');

nrows = fscanf(fid,'%i',1);
ncols = fscanf(fid,'%i',1);

rows_size = fscanf(fid,'%i',1);
rows = fscanf(fid,'%i',[rows_size 1]);

cols_size = fscanf(fid,'%i',1);
cols = fscanf(fid,'%i',[cols_size 1]);
vals = fscanf(fid,'%lf',[cols_size 1]);

fclose(fid);

J = sparse(nrows,ncols);
for i=1:nrows
    idxs = ((rows(i)+1):rows(i+1));
    J(i,cols(idxs)+1) = vals(idxs);
end


end

