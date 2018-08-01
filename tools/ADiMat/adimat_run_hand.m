function [J, fval] = adimat_run_hand(do_F_mode, params, data, us)

if ~do_F_mode
   error('adimat_run_hand: reverse not implemented.'); 
end

%other options include:
%   arrderivclass, arrderivclassvxdd, opt_derivclass,
%   opt_sp_derivclass, mat_derivclass, or scalar_directderivs
adimat_derivclass('vector_directderivs');

if nargin < 4
    d_params = createFullGradients(params);
    [d_err, fval] = d_hand_objective(d_params, params, data);
else
    ndd = numel(params) + 2;
    option('ndd', ndd);
    
    d_params = zeros([ndd,size(params)]);
    d_us = zeros([ndd,size(us)]);
    d_us(1,1,:)=1;
    d_us(2,2,:)=1;
    d_params(3:end,:,:)=eye(26);
    
    [d_err, fval] = d_hand_objective_complicated(d_params, params,...
        d_us, us, data);
end

J = admJacFor(d_err);

end