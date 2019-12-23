% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function [ J, err ] = mupad_gmm_objective( nruns, params,...
    x,hparams,do_jacobian)
%mupad_gmm_objective Use mexed files

d = size(x,1);
k = size(params.alphas,2);
n = size(x,2);

mexname = sprintf('example_gmm_objective_mex_d%d_K%d', d, k);
if ~exist(mexname, 'file')
    disp(['error: file not found: ' mexname])
    J = [];
    err = [];
else
    params_vec = repmat(au_deep_vectorize(params),1,n);
    data = [x; 
        repmat([max(x(:,1)); hparams(:)],1,n)];
    for i=1:nruns
        J = feval(mexname,params_vec,data,do_jacobian);
    end
    err = J(1);
end
end

