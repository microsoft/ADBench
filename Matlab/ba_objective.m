function [reproj_err, w_error] = ba_objective( cams, X, w, obs )
%BA_OBJECTIVE Bundle adjustment objective function
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
% %         F_PRIOR_ERR 1 x n-2 
% %               temporal prior on focals
%         W_ERR 1 x p 
%               1-w^2 
%
%  Xcam = R * (X - C)
%  distorted = radial_distort(projective2euclidean(Xcam),radial_parameters)
%  proj = distorted * f + principal_point
%  err = sqsum(proj - measurement)

n = size(cams,2);
m = size(X,2);
p = size(obs,2);

reproj_err = zeros(2,p,'like',cams);
for i=1:p
    camIdx = obs(1,i);
    ptIdx = obs(2,i);
    
    reproj_err(:,i) = ba_compute_reproj_err(cams(:,camIdx),...
        X(:,ptIdx),w(i),obs(3:4,i));
end

w_error = 1 - w.^2;

end
