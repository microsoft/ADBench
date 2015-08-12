function [ J, err ] = gmm_objective_d_symbolic( nruns, params,...
    x,hparams )
%GMM_OBJECTIVE_D_SYMBOLIC Use mexed files

d = size(x,1);
k = size(params.alphas,2);
n = size(x,2);

params_vec = repmat(au_deep_vectorize(params),1,n);

do_jacobian = true;

mexname = sprintf('example_gmm_objective_mex_d%d_K%d', d, k);
if ~exist(mexname, 'file')
    disp(['error: file not found: ' mexname])
    J = [];
    err = [];
else
    data = [x; 
        repmat([max(x(:,1)); hparams(:)],1,n)];
    for i=1:nruns
        J = feval(mexname,params_vec,data,do_jacobian);
    end
    err = J(1);
end
end

