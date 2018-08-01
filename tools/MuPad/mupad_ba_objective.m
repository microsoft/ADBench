function [compressedJ,reproj_err,w_err] = ...
    mupad_ba_objective(cams, X, w, obs,do_jac)
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

params = [cams(:,obs(1,:));X(:,obs(2,:));w];
err_and_J = mupad_ba_compute_reproj_err_mex(params,obs(3:4,:),do_jac);
reproj_err = reshape(err_and_J(1,:)',2,p);

dummy = zeros(0,p);
err_and_J2 = mupad_ba_compute_weight_err_mex(w,dummy,do_jac);
w_err = err_and_J2(1,:);

if do_jac
    compressedJ = {err_and_J(2:end,:), err_and_J2(2,:)};
else
    compressedJ=[];
end

end