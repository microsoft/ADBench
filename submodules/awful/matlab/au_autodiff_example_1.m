function residual = au_autodiff_example_1(params, data)
% Example for autodiff: Bundle residual for one phi term in the below.
%
%   sum_ij || m_ij - phi(K, P_i, X_j) ||
%

if nargin == 0
    %% TEST CASE
   
    params = [rand(5,1); rand(6,1); rand(3,1)];
    data = rand(2,1);
    
    tic
    au_autodiff_generate(@au_autodiff_example_1, params, data, 'c:/tmp/au_autodiff_example_1_mex.cpp');
    toc
    
    
    %% evaluate many terms in one call
    nterms = 3;
    allparams = rand(14,nterms);
    alldata = rand(2,nterms);
    out = au_autodiff_example_1_mex(allparams,alldata,true);
    residuals = out(1,:)
    J = out(2:end,:)
    return
end

K_params = params(1:5);
f = K_params(1);
cx = K_params(2);
cy = K_params(3);
kappa1 = K_params(4);
kappa2 = K_params(5);

sqr = @(x) x*x;
applyradial = @(x,k1,k2) (1 + k1*x'*x + k2*sqr(x'*x))*x;

K = [f 0 cx;
    0 f cy; 
    0 0 1];

P_params = params(6:11);
Rotation = au_rodrigues(P_params(1:3),1,1);
Translation = P_params(4:6);

X = params(12:14);

% perspective projection
pi = @(x) x(1:2)/x(3);

camX = K*(Rotation*X + Translation);

m = data;
residual = m - applyradial(pi(camX), kappa1, kappa2);
