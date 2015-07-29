function [reproj_err, f_prior_err, w_error] = ...
    ba_objective( cams, X, w, obs )
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
%         F_PRIOR_ERR 1 x n-2 
%               temporal prior on focals
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

R = cell(1,n);
for i=1:n
    R{i} = au_rodrigues(cams(1:3,i));
end
C = cams(4:6,:);
f = cams(7,:);
princ_pt = cams(8:9,:);
rad_params = cams(10:11,:);

reproj_err = zeros(2,p);
for i=1:p
    camIdx = obs(1,i);
    Xcam = R{camIdx} * (X(:,obs(2,i)) - C(:,camIdx));
    Xcam_e = Xcam(1:end-1)/Xcam(end);
    distorted = radial_distort(Xcam_e,rad_params(:,camIdx));
    proj = distorted * f(camIdx) + princ_pt(:,camIdx);
    reproj_err(1,i) = w(i)*(proj(1) - obs(3,i));
    reproj_err(2,i) = w(i)*(proj(2) - obs(4,i));
end

f_prior_err = f(1:(n-2)) - 2*f(2:(n-1)) + f(3:n);
w_error = 1 - w.^2;

end

function x = radial_distort(x,kappa) 
    r2 = x(2)*x(2) + x(1)*x(1);
    L = 1 + kappa(1)*r2 + kappa(2)*r2*r2;
    x = x * L;
end
