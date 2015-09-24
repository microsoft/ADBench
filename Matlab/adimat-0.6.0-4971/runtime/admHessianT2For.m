% function [Hessian, Jac, f1, f2, ..., timings] = ...
%    admHessian(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Compute second order derivatives of function given by handle,
% evaluated at the arguments arg1, arg2, ..., argN and return the
% Hessian matrix. This works by running admOptions.admDiffFunction to
% compute second order Taylor coefficients and combine them to the
% Hessian entries.
%
%  The following fields in the admOptions struct apply specifically to
% this function:
% 
%  - admDiffFunction must be able to return second order Taylor
%  coefficients when option derivOrder is set to 2. Currently
%  admDiffFunc can be one of:
%   - @admTaylorFor (default)
%   - @admTaylorVFor
%   - @admDiffFor
%   - @admDiffFD
%
%  It is recommened to the default choice of @admTaylorFor, or
%  @admTaylorVFor as these, functions compute second order Taylor
%  coefficients precisely and efficiently. Results using @admDiffFD
%  are not as precise, while using @admDiffFor is less efficient.
%
%  Seeding (computing Hessian products) is not supported, seedMatrix
%  is ignored.
%
% see also admHessian, admTaylorFor, admTaylorVFor, admDiffFor,
% admDiffFD
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                                   TU Darmstadt
function [varargout] = admHessianT2For(handle, seedMatrix, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end

  nFuncArgs = length(funcArgs);
  independents = admOpts.independents;
  if isempty(independents)
    independents = 1:nFuncArgs;
  end
  nActArgs = length(independents);

  admOpts.x_nCompInputs = admTotalNumel(funcArgs{independents});

  postMult = false;

  [seedV, seedW, seedRev, seedC, admOpts.coloring] = admMakeUserSeedMatricesHess(seedMatrix, admOpts);
  if isempty(admOpts.t2formode)

    if isequal(seedC, 1)
      nddSeed = admOpts.x_nCompInputs;
    else
      nddSeed = size(seedC, 2);
    end
    if isequal(seedV, 1)
      nddSeed2 = admOpts.x_nCompInputs;
    else
      nddSeed2 = size(seedV, 1);
    end
    
    nddPostMult = admOpts.x_nCompInputs + admOpts.x_nCompInputs .* (admOpts.x_nCompInputs - 1) ./ 2;
    nddMult = nddSeed2 + nddSeed + nddSeed2.*nddSeed;
    
    if nddPostMult < nddMult
      postMult = true;
    end
  else
    if strcmp(admOpts.t2formode, 'postmult')
      postMult = true;
    end
  end
  
  if postMult
    [varargout{1:nargout}] = admHessianT2ForPostMultS(handle, {seedRev, seedV, seedW}, funcArgs{:}, admOpts);
  else
    [Hessian Jac varargout{3:nargout}] = admHessianT2ForMultS(handle, {seedRev, seedV, seedC}, funcArgs{:}, admOpts);
    if ~isempty(admOpts.coloring)
      Jac = admUncompressJac(Jac, admOpts.JPattern, admOpts.coloring, seedW);
      Hessian = admUncompressHess(Hessian, admOpts.JPattern, admOpts.coloring, seedV, seedW);
    end
    varargout(1:2) = {Hessian Jac};
  end
  
% $Id: admHessianT2For.m 4678 2014-09-15 12:12:31Z willkomm $
