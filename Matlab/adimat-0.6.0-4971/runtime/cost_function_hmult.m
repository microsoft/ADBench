% function [HessV] = cost_function_hmult(x, V, params, adopts)
%
% An example wrapper function to adapt ADiMat to Matlab's fminunc when
% using the HessMult field.
% 
% [HessV] = cost_function_hmult(x, V, params, adopts)
%
% Run admHessian with seed vector V so that it returns the product H*V
% of the Hessian and vector V evaluated at point x. Additional
% parameters to the objective function are in params. You should then
% also set the optimset field HessMult to an anonymous function that
% calls this wrapper function:
%
% params = ...
% adopts = admOptions(...)
% opt = optimset;
% opt.GradObj = 'on';
% opt.Hessian = 'on';
% opt.HessMult = @(Hinfo, V) cost_function_hmult(Hinfo, V, params, adopts)
%
% Use an extension field to transmit the info that you're using
% HessMult to the objective function:
%
% adopts.x_useHessMult = 1;
%
% In the objective function return the current point x as Hinfo, for
% an example see cost_function_wrapper.
%
% See also cost_function_wrapper
%
function [HessV] = cost_function_hmult(x, V, params, adopts)
  [HessV] = admHessian(@cost_function, V, x, params, adopts);
end

% $Id: cost_function_hmult.m 3681 2013-05-29 17:21:08Z willkomm $
