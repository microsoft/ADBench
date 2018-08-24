% function [Hessian, Jac, varargout] = admHessian(handle, seedMatrix, ...
%                                 arg1, arg2, ..., argN, admOptions?)
%
%  Compute second order derivatives of function given by handle,
% evaluated at the arguments arg1, arg2, ..., argN and return the
% Hessian matrix. Options can be passed as the last argument. This
% function works by either one of two stategies, which can be chosen
% via the field hessianStrategy in the admOptions structure.
%
%  The following fields in the admOptions struct apply specifically to
% this function:
% 
%  - hessianStrategy:
%
%   a) If set to 't1rev' uses an overloading-over-reverse-mode (OORM)
%   approach, i.e. it uses an OO class for propagating first order
%   derivatives, and runs the RM-differentiated function with it. When
%   seedMatrix = 1, this computes the full Hessian matrix in time
%   O(n*m), where n is the number of input components and m the number
%   of output components. A product of the Hessian with seedMatrix can
%   be computed in time O(p*m), where p is the number of columns of
%   the seedMatrix. This case is handled by running the function
%   admHessianT1Rev. For more details and available options, type help
%   admHessianT1Rev.
%
%   b) If set to 't2for' uses a source-transformation approach for
%   propagating truncated taylor series and computes the entries of
%   the Hessian matrix by linear compination of n + (n+1)*n/2
%   directional derivatives. This method can only compute the full
%   Hessian, i.e. the seedMatrix is ignored, and requires time O(n),
%   where n is the number of input components. This case is handled by
%   running the function admHessianT2For. For more details and
%   available options, type help admHessianT2For.
%
%   c) If set to 'fd' uses finite differences (admDiffFD) on top of
%   any first order differentiation method, by default admDiffRev. For
%   more details and available options, type help admHessianFD.
%
%   d) If set to 'cv' uses the complex variable method
%   (admDiffComplex) on top of any first order differentiation method,
%   by default admDiffRev. For more details and available options,
%   type help admHessianFD.
%
%  Example: Compute Hessian of function [x y] = f(a, b)
%    
%     [H x y times] = admHessian(@f, 1, a, b)
%
% H is a 2d matrix if the number of components in the dependent
% variables is 1. Otherwise H is a 3d tensor, where H(i,j,k) is the
% (j,k)-th entry of the Hessian of output component i, counting all
% components in the dependent variables. You can obtain the Hessian of
% the i-th output component by using:
%
%     squeeze(H(i,:,:))
%
%  In addition to H, admHessian returns the Jacobian matrix or
% gradient, the function results of f and some timing results. In the
% example above, x and y are the function results and times is a
% structure with timing information.
%
% see also admOptions, admHessianT1Rev, admHessianT2For.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                                   TU Darmstadt
function [varargout] = admHessian(handle, seedMatrix, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
    admOpts = admPreprocessOptions(admOpts);
    if admOpts.checkoptions
      admCheckOptions(admOpts);
    end
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end
  admOpts.checkoptions = false;
  
  hStrat = lower(admOpts.hessianStrategy);

  switch hStrat
   case {'t1rev', ''}
    [varargout{1:nargout}] = admHessianT1Rev(handle, seedMatrix, funcArgs{:}, admOpts);
   case {'t2for'}
    [varargout{1:nargout}] = admHessianT2For(handle, seedMatrix, funcArgs{:}, admOpts);
   case {'for2'}
    [varargout{1:nargout}] = admDiffFor2(handle, seedMatrix, funcArgs{:}, admOpts);
   otherwise
    error('adimat:admHessian:unknownHessianStrategy', ...
          'The value for options field hessianStrategy is invalid: %s',...
          hStrat);
  end
  
% $Id: admHessian.m 4646 2014-09-12 21:51:54Z willkomm $
