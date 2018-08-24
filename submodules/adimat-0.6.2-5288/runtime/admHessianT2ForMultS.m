% function [Hessian, Jac, varargout] = ...
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
%   - @admTaylorVFor (default)
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
function [Hessian, Jac, varargout] = admHessianT2ForMultS(handle, seedMatrixIn, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end

  admDiffFunc = admOpts.admDiffFunction;
  if isempty(admDiffFunc)
    admDiffFunc = @admTaylorFor;
    admDiffFuncName = func2str(admDiffFunc);
  elseif isa(admDiffFunc, 'function_handle')
    admDiffFuncName = func2str(admDiffFunc);
  else
    admDiffFuncName = admDiffFunc;
    admDiffFunc = str2func(admDiffFunc);
  end

  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
    handle = str2func(handle);
  end

  if isempty(admOpts.nargout)
    fNargout = nargout(functionName);
    if fNargout < 0
      fNargout = 1;
      warning('adimat:admDiffHessian:cannotGetNargout', ['Could not ' ...
                          'determine nargout of the function ' ...
                          '%s,\npresumably because it has a variable number of ' ...
                          'output arguments (varargout).\nAssuming nargout(%s) ' ...
                          '= 1,\notherwise you can use nargout option ' ...
                          'field to specify the correct value.'], functionName, functionName);
    end
    % make warning go away in call to admDiffFunc
    admOpts.nargout = fNargout;
  else
    fNargout = admOpts.nargout;
  end

  nFuncArgs = length(funcArgs);
  independents = admOpts.independents;
  if isempty(independents)
    independents = 1:nFuncArgs;
  end
  nActArgs = length(independents);

  dependents = admOpts.dependents;
  if isempty(dependents)
    dependents = 1:fNargout;
  end
  nActResults = length(dependents);

  admOpts.x_nCompInputs = admTotalNumel(funcArgs{independents});

  [seedV seedMatrix seedRev] = admUnpackUserSeedMatricesHess(seedMatrixIn, admOpts);

  if isequal(seedMatrix, 1)
    seedMatrix = eye(admOpts.x_nCompInputs);
  end
  nddSeed = size(seedMatrix, 2);

  if isequal(seedV, 1)
    seedV = eye(admOpts.x_nCompInputs);
  end
  nddSeed2 = size(seedV, 1);

  nddMore = nddSeed2 * nddSeed;

  % Construct derivative directions needed for Hessian
  S = [seedMatrix seedV.' zeros(admOpts.x_nCompInputs, nddMore)];
  
  offs = nddSeed2+nddSeed;
  for i=1:nddSeed2
    for j=1:nddSeed
      S(:,offs + i + (j-1).*nddSeed2) = S(:,nddSeed+i) + S(:,j);
    end
  end
  
%  fprintf(admLogFile(), 'Need %d T2 derivative directions in this case\n',size(S,2));
  
  % Compute 2nd order Taylor coefficients T using derivative directions
  % in S
  admOpts.derivOrder = 1:2;
  admOpts.JPattern = []; % don't compress S!
  [T, varargout{1:fNargout}] = admDiffFunc(handle, S, funcArgs{:}, admOpts);
  
  Jac = T(:,1:nddSeed,1);
  
  nCompOutputs = size(Jac, 1);

  if ischar(seedRev) && (isequal(seedRev, 's') || isequal(seedRev, 'sum'))
    % seedRev = ones(1, nCompOutputs);
    nrdd = 1;
  elseif isequal(seedRev, 1)
    % seedRev = eye(nCompOutputs);
    nrdd = nCompOutputs;
  else
    nrdd = size(seedRev, 1);
  end
  
  T2 = T(:,:,2);
  if ischar(seedRev) && (strcmp(seedRev, 's') || strcmp(seedRev, 'sum'))
    T2 = sum(T2, 1);
  elseif ~isequal(seedRev, 1)
    T2 = seedRev * T(:,:,2);
  end
  
  % Construct 3d tensor of Hessians of components
  Hessian = zeros(nddSeed2, nddSeed, nrdd);
  for i=1:nddSeed2
    for j=1:nddSeed
      Hessian(i, j, :) = (T2(:,offs + i + (j-1).*nddSeed2) - T2(:,nddSeed+i) - T2(:,j));
    end
  end
  
% $Id: admHessianT2ForMultS.m 4609 2014-07-09 13:28:38Z willkomm $
