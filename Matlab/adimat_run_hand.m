function [J, fval] = adimat_run_hand(do_F_mode, params, data)

if ~do_F_mode
   error('adimat_run_hand: reverse not implemented.'); 
end

%other options include:
%   arrderivclass, arrderivclassvxdd, opt_derivclass,
%   opt_sp_derivclass, mat_derivclass, or scalar_directderivs
adimat_derivclass('vector_directderivs');

d_params = createFullGradients(params);
[d_err, fval] = d_hand_objective(d_params, params, data);

J = admJacFor(d_err);

end