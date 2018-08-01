function e = au_ad_bundle_fun(params, data)

% AU_AD_BUNDLE_FUN   Objective function for bundle
%   params = [r1 r2 r3     -- Rodrigues rotation (axis * angle)
%             t1 t2 t3     -- translation
%             f u0 v0      -- calibration
%             k1 k2        -- radial
%             X1 X2 X3 X4  -- 3D point]
%
%   out = [projected_x, projected_y]
%
%   C = R * pi(X) + T
%   c = pi(C)
%   d = radial(c, [k1 k2]);
%   out = f * d + [u0 v0];

%%
rot = params(1:3);
trans = params(4:6);
f = params(7);
principal_point = params(8:9);
kappa = params(10:11);
X = params(12:15);

R = au_rodrigues(rot);
X = X(1:3)/X(4);
C = R * X + trans;
pi = @(X) X(1:end-1)/X(end);
c = pi(C);
d = radial(c, kappa);
e = d * f + principal_point;

%%
function x = radial(p,kappa) 
r2 = p(2)*p(2) + p(1)*p(1);
L = 1 + kappa(1)*r2 + kappa(2)*r2*r2;
x = p * L;
