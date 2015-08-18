function [J, fval] = gmm_objective_adimat(do_F_mode,...
    alphas,means,inv_cov_factors,x,hparams)
%GMM_OBJECTIVE_ADIMAT Call already translated function 
%                   and create our gradient

if do_F_mode
    adimat_derivclass('vector_directderivs')
    [d_alphas,d_means,d_inv_cov_factors] = ...
        createFullGradients(alphas,means,inv_cov_factors);
    [J, fval] = d_gmm_objective(d_alphas, alphas, d_means, ...
        means, d_inv_cov_factors, inv_cov_factors, x, hparams);
    J = J';
else
  clear('-global', 'init_a_*');
  clear adimat_stack_info;
    %only 1 row -> scalar but other options include:
    %   arrderivclass, arrderivclassvxdd, opt_derivclass, 
    %   opt_sp_derivclass, mat_derivclass, or scalar_directderivs
    adimat_derivclass('scalar_directderivs') 
    a_err = 1; % [a_err] = createFullGradients(1); 1 is "problem size"
    [a_alphas, a_means, a_inv_cov_factors, fval] = ...
        a_gmm_objective(alphas, means, inv_cov_factors, x, hparams, a_err);
    J = [a_alphas(:); a_means(:); a_inv_cov_factors(:)]';
end

end

