% Copyright (c) Microsoft Corporation.
% Licensed under the MIT license.

function [J, fval] = adimat_run_gmm(do_F_mode,do_adimat_vector,...
    alphas,means,inv_cov_factors,x,hparams)
%adimat_run_gmm Call already translated function 
%                   and create our gradient

if do_adimat_vector
    objective = 'gmm_objective_vector_repmat';
else
    objective = 'gmm_objective';
end

if do_F_mode
    adimat_derivclass('vector_directderivs')
    [d_alphas,d_means,d_inv_cov_factors] = ...
        createFullGradients(alphas,means,inv_cov_factors);
    [J, fval] = feval(['d_' objective],d_alphas, alphas, d_means,...
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
    [a_alphas,a_means,a_inv_cov_factors,fval] = ...
        feval(['a_' objective],alphas,means,inv_cov_factors,x...
        ,hparams,a_err);
    J = [a_alphas(:); a_means(:); a_inv_cov_factors(:)]';
end

end

