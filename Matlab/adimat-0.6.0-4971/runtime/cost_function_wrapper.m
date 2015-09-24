% function [q, grad, Hess] = cost_function_wrapper(x, params, adopts)
%
% An example wrapper function to adapt ADiMat to Matlab's fminunc
% 
% [q] = cost_function_wrapper(x, params, adopts)
%
% Returns just the function result q.
%
% [q grad] = cost_function_wrapper(x, params, adopts)
%
% Returns the function result q and the gradient grad computed with
% admDiffRev. Set optimset field GradObj to 'On' to use this.
%
% [q grad Hess] = cost_function_wrapper(x, params, adopts)
%
% When adopts does not have the extension field x_useHessMult or that
% has an empty value, returns the function result q, gradient grad,
% and the full Hessian Hess.  Set optimset field Hessian to 'On' to
% use this.
%
% When adopts has the extension field x_useHessMult and that is
% nonempty, return the current argument x as the Hess output. This
% corresponds to the Hinfo value in fminunc's documentation. You
% should then also set the optimset field HessMult to a function
% handle that can compute Hessian-vector products. See
% cost_function_hmult for an example.
%
% See also cost_function_hmult
%
function [q, grad, Hess] = cost_function_wrapper(x, params, adopts)
  if nargout == 1
    q = cost_function(x, params);
  elseif nargout == 2
    [grad q] = admDiffRev(@cost_function, 1, x, params, adopts);
  else
    if ~isfield(adopts, 'x_useHessMult') || isempty(adopts.x_useHessMult)
      % compute full Hessian here
      [Hess grad q] = admHessian(@cost_function, 1, x, params, adopts);
    else
      % when using HessMult, we use HInfo to save the current arguments
      [grad q] = admDiffRev(@cost_function, 1, x, params, adopts);
      Hess = x;
    end
  end
end

% $Id: cost_function_wrapper.m 3681 2013-05-29 17:21:08Z willkomm $
