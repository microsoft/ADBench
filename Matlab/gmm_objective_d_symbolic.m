function [ J, err ] = gmm_objective_d_symbolic( nruns, params,...
    x,hparams )
%GMM_OBJECTIVE_D_SYMBOLIC Use mexed files

d = size(x,1);
k = size(params.alphas,2);
n = size(x,2);

params_vec = repmat(au_deep_vectorize(params),1,n);

do_jacobian = true;
if d==2 && k==3
    df = @(data) autogen_example_gmm_objective_mex_d2_K3(params_vec,data,do_jacobian);
elseif d==2 && k==10
    df = @(data) autogen_example_gmm_objective_mex_d2_K10(params_vec,data,do_jacobian);
elseif d==2 && k==25
    df = @(data) autogen_example_gmm_objective_mex_d2_K25(params_vec,data,do_jacobian);
elseif d==2 && k==50
    df = @(data) autogen_example_gmm_objective_mex_d2_K50(params_vec,data,do_jacobian);
elseif d==10 && k==5
    df = @(data) autogen_example_gmm_objective_mex_d10_K5(params_vec,data,do_jacobian);
elseif d==10 && k==25
    df = @(data) autogen_example_gmm_objective_mex_d10_K25(params_vec,data,do_jacobian);
elseif d==20 && k==5
    df = @(data) autogen_example_gmm_objective_mex_d20_K5(params_vec,data,do_jacobian);
end

data = [x; 
        repmat([max(x(:,1)); hparams(:)],1,n)];
for i=1:nruns
    J = df(data);
end

err = J(1);

end

