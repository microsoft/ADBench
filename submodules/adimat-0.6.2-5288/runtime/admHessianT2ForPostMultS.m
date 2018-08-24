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
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                                   TU Darmstadt
function [Hessian, Jac, varargout] = admHessianT2ForPostMultS(handle, seedMatrix, varargin)
  
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
  elseif ~isa(admDiffFunc, 'function_handle')
    admDiffFunc = str2func(admDiffFunc);
  end

  if isempty(admOpts.nargout)
    if isa(handle, 'function_handle')
      functionName = func2str(handle);
    else
      functionName = handle;
      handle = str2func(handle);
    end
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

  ndd = admOpts.x_nCompInputs * (admOpts.x_nCompInputs + 1) / 2;

  % Construct derivative directions needed for Hessian
  S = [eye(admOpts.x_nCompInputs) zeros(admOpts.x_nCompInputs, ndd - admOpts.x_nCompInputs)];
  
  offs = admOpts.x_nCompInputs+1;
  for i=2:admOpts.x_nCompInputs
    for j=1:i-1
      S([i j],offs) = 1;
      offs = offs + 1;
    end
  end

%  fprintf(admLogFile(), 'Need %d T2 derivative directions in this case\n',size(S,2));
  
  % Compute 2nd order Taylor coefficients T using derivative directions
  % in S
  admOpts.derivOrder = 1:2;
  [T, varargout{1:fNargout}] = admDiffFunc(handle, S, funcArgs{:}, admOpts);
  
  Jac = T(:,1:admOpts.x_nCompInputs,1);

  nCompOutputs = size(Jac, 1);
  
  [seedV seedMatrix seedRev] = admUnpackUserSeedMatricesHess(seedMatrix, admOpts);

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
    T2 = seedRev * T2;
  end

  % Construct 3d tensor of Hessians of components
  Hessian = zeros(admOpts.x_nCompInputs, admOpts.x_nCompInputs, nrdd);
  offs = admOpts.x_nCompInputs+1;
  for i=1:admOpts.x_nCompInputs
    for j=1:i-1
      Hessian(i, j, :) = (T2(:,offs) - T2(:,i) - T2(:,j));
      offs = offs + 1;
    end
  end
  Hessian = Hessian + permute(Hessian, [2 1 3]);
  for i=1:admOpts.x_nCompInputs
    Hessian(i, i, :) = T2(:, i) .* 2;
  end
  
  if ~isequal(seedMatrix, 1)
    Jac = Jac * seedMatrix;
    Hessian = admMatMultV3(Hessian, seedMatrix);
  end

  if ~isequal(seedV, 1)
    Hessian = admMatMultV3(seedV, Hessian);
  end

% $Id: admHessianT2ForPostMultS.m 4609 2014-07-09 13:28:38Z willkomm $
