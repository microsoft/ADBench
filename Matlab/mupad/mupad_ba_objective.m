function [J,reproj_err,w_err] = mupad_ba_objective(cams, X, w, obs,do_jac)
%         CAMERAS c x n 
%               matrix containing parameters of n cameras
%               for now, supported format is only
%                 [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]'
%               r1,r2,r3 are angle-axis rotation parameters (Rodrigues)
%               [C1 C2 C3]' is the camera center
%               f is the focal length in pixels
%               [u0 v0]' is the principal point
%               k1,k2 are radial distortion parameters
%         X 3 x m 
%               matrix containg m points
%         W 1 x p 
%               vector of weigths for Zach robustifier
%         OBS 2 x p 
%               contains p observations
%               i.e. [camIdx ptIdx x y]
%               where [x y]' is a measurement (a feature)   
%         REPROJ_ERR 2 x p 
%               reprojection errors
%         W_ERR 1 x p 
%               1-w^2 

addpath('awful/matlab');

n = size(cams,2);
m = size(X,2);
p = size(obs,2);
ncam_params = size(cams,1);
batchsz = ncam_params + 3 + 1;
batch = 1:batchsz;

if do_jac
    nnonzero = batchsz*2*p + p;
    rows = zeros(1,nnonzero);
    cols = rows;
    vals = rows;
end

reproj_err = zeros(2,p);
offset = 0;
for i=1:p
    camIdx = obs(1,i);
    ptIdx = obs(2,i);
    
    params.cam = cams(:,camIdx);
    params.X = X(:,ptIdx);
    params.w = w(i);
    err_and_J = mupad_ba_compute_reproj_err_mex(...
        au_deep_vectorize(params),obs(3:4,i),do_jac);
    
    reproj_err(:,i) = err_and_J(1,:);
    if do_jac        
        cam_offset = (camIdx-1)*ncam_params;
        camIdxs = (1:ncam_params) + cam_offset;
        pt_offset = n*ncam_params + (ptIdx-1)*3;
        ptIdxs = (1:3) + pt_offset;
        wIdx = n*ncam_params + m*3 + i;
        
        colIdxs = [camIdxs ptIdxs wIdx];
        rowIdx=2*(i-1)+1;
        rows(batch + offset) = rowIdx;
        cols(batch + offset) = colIdxs;
        vals(batch + offset) = err_and_J(2:end,1);
        offset = offset + batchsz;
        
        rows(batch + offset) = rowIdx+1;
        cols(batch + offset) = colIdxs;
        vals(batch + offset) = err_and_J(2:end,2);
        offset = offset + batchsz;
    end
end

offset = offset + 1;
w_err = zeros(1,p);
row_offset = 2*p;
col_offset = n*ncam_params + m*3;
dummy = zeros(0,1);
for i=1:p
    err_and_J = mupad_ba_compute_weight_err_mex(w(i),dummy,do_jac);
    w_err(i) = err_and_J(1);
    
    rows(offset) = i + row_offset;
    cols(offset) = i + col_offset;
    vals(offset) = err_and_J(2);
    offset = offset + 1;
end

if do_jac
   J = sparse(rows, cols, vals, 3*p, n*ncam_params + m*3 + p);
else
   J = []; 
end

end