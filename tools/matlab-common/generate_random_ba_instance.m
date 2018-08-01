function [cams,X,w,obs] = generate_random_ba_instance(n,m,p)
%GENERATE_RANDOM_BA_INSTANCE
%         N is the number of cameras
%         M is the number of points
%         P is the number of observations
%
%         CAMERAS c x n matrix containing parameters of n cameras
%             for now, supported format is only
%               [r1 r2 r3 C1 C2 C3 f u0 v0 k1 k2]'
%             r1,r2,r3 are angle-axis rotation parameters (Rodrigues)
%             [C1 C2 C3]' is the camera center
%             f is the focal length in pixels
%             [u0 v0]' is the principal point
%             k1,k2 are radial distortion parameters
%         X 3 x m matrix containg m points
%         OBS 2 x p contains p observations
%               i.e. [camIdx ptIdx x y]
%               where [x y]' is a measurement (a feature)   

% any (0,1) number
w = rand(1,p);

% points in a cube 10x10x10
X = rand(3,m) * 10;

cams = zeros(11,n);
% random rotations
cams(1:3,:) = randn(3,n);
% cameras in a little larger cube than points
cams(4:6,:)  = rand(3,n) * 100;
% f
cams(7,:) = rand(1,n) * 1000;
% u0 v0
cams(8:9,:) = randn(2,n) * 10;
% radial params
cams(10:11,:) = rand(2,n)*0.1;

obs = zeros(2,n*m);
for i=0:(n-1)
    idx = i*m;
    obs(1,idx+(1:m)) = i+1;
    obs(2,idx+(1:m)) = 1:m;
end

obs = obs(:,randperm(n*m));

obs = obs(:,1:min(p,m*n));

for i=1:p
    camIdx = obs(1,i);
    R = au_rodrigues(cams(1:3,camIdx));
    Xcam = R * (X(:,obs(2,i)) - cams(4:6,camIdx));
    Xcam_e = Xcam(1:end-1)/Xcam(end);
    distorted = radial_distort(Xcam_e,cams(10:11,camIdx));
    proj = distorted * cams(7,camIdx) + cams(8:9,camIdx);
    obs(3:4,i) = proj + randn(2,1); % add noise
end

end

function x = radial_distort(x,kappa) 
    r2 = x(2)*x(2) + x(1)*x(1);
    L = 1 + kappa(1)*r2 + kappa(2)*r2*r2;
    x = x * L;
end

