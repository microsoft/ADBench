% function [Hessian, Jacobian, varargout] = admDiffFor2(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
% see also admHessian, admDiffFor.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Hessian, Jacobian, varargout] = admDiffFor2(handle, seedMatrix, varargin)
  
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

  admOpts.mode = 'F';
  
  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
    handle = str2func(handle);
  end

  if isempty(admOpts.nargout)
    fNargout = nargout(functionName);
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

  admOpts.parameters.funcprefix = 'tmp_';

  admOpts2 = admOpts;
  admOpts2.independents = [];
  for n=1:length(independents)
    offs = n-1;
    admOpts2.independents(end+1:end+2) = [independents(n)+offs independents(n)+offs+1];
  end
  admOpts2.dependents = [];
  for n=1:length(dependents)
    offs = n-1;
    admOpts2.dependents(end+1:end+2) = [dependents(n)+offs dependents(n)+offs+1];
  end
  
  admOpts2.parameters.gradprefix = 'h_';
  admOpts2.parameters.funcprefix = 'h_';

  interFunctionName = [admOpts.parameters.funcprefix functionName];
  resultFunctionName = [admOpts2.parameters.funcprefix admOpts.parameters.funcprefix functionName];

  [doTransform] = admCheckWhetherToTransformSource(admOpts2, functionName, resultFunctionName);

  if doTransform
    clear(resultFunctionName);
    times_transformation = tic;
    % first pass
    fprintf(admLogFile, 'Differentiating function %s in forward mode (FM) to produce\n %s...\n', ...
            functionName, interFunctionName);
    [r msg] = admTransform(handle, admOpts);
    if ~r
      error('adimat:admDiffFor:transformationFailed', ...
            ['The transformation of %s with admTransform to produce %s has failed\n' ...
             '%s'], functionName, resultFunctionName, msg);
      return
    end

    % second pass
    fprintf(admLogFile, 'Differentiating function %s in forward mode (FM) to produce\n %s...\n', ...
            interFunctionName, resultFunctionName);
    [r msg] = admTransform(interFunctionName, admOpts2);
    times_transformation = toc(times_transformation);
    fprintf(admLogFile, 'Differentiation took %g s.\n', times_transformation);
    if ~r
      error('adimat:admDiffFor:transformationFailed', ...
            ['The transformation of %s with admTransform to produce %s has failed\n' ...
             '%s'], functionName, resultFunctionName, msg);
      return
    end
    
    admCheckTransformedFileExists(resultFunctionName);
  end

  diffFunction = str2func(resultFunctionName);
  
  admOpts.x_nCompInputs = admTotalNumel(funcArgs{independents});

  nDFResults = fNargout + nActResults;
  actOutIndices = admDerivIndices(dependents);
  
  % check does not work with 2nd order yet
  % admCheckNArgsFor(functionName, resultFunctionName, ...
  %                   nFuncArgs, nActArgs, fNargout, nActResults);

  [seedV, seedW, seedRev] = admMakeUserSeedMatricesHess(seedMatrix, admOpts);
  
  if isequal(seedV, 1)
    seedV = eye(admOpts.x_nCompInputs);
  end
  if isequal(seedW, 1)
    seedW = eye(admOpts.x_nCompInputs);
  end

  if admOpts.x_nCompInputs ~= size(seedW, 1)
    error('adimat:secondOrderFM:nonConformingSeedSize', ...
          ['In second order Forward Mode (FM), the number of rows of the seed ' ...
           'matrix S must be identical with the total number of ' ...
           'components in the (active) function arguments. However, ' ...
           'admTotalNumel(varargin{indeps}) == %d and size(W, 1) ' ...
           '= %d'], admOpts.x_nCompInputs, size(seedW, 1));
  end
  if admOpts.x_nCompInputs ~= size(seedV, 2)
    error('adimat:secondOrderFM:nonConformingSeedSize', ...
          ['In second order Forward Mode (FM), the number of columns of the seed ' ...
           'matrix V must be identical with the total number of ' ...
           'components in the (active) function arguments. However, ' ...
           'admTotalNumel(varargin{indeps}) == %d and size(V, 2) ' ...
           '= %d'], admOpts.x_nCompInputs, size(seedV, 2));
  end
  
  admOpts.derivOrder = 1:2;
  admOpts.admDiffFunction = 'admDiffFor2';
  admSelectDerivClass(size(seedV, 1) .* size(seedW, 2), admOpts);

  [HessianPre, Jacobian, varargout{1:fNargout}] = ...
      admComputeDerivFor2(diffFunction, seedV, seedW, independents, ...
                          dependents, fNargout, funcArgs{:});
  
  if ischar(seedRev) && (strcmp(seedRev, 's') || strcmp(seedRev, 'sum'))
    Hessian = sum(HessianPre, 3);
  
  elseif ~isequal(seedRev, 1)
    nrdd = size(seedRev, 1);

    Hessian = zeros([size(HessianPre, 1) size(HessianPre, 2) nrdd]);
    for k=1:size(Hessian, 1)
      Hessian(k,:,:) = squeeze(HessianPre(k,:,:)) * seedRev.';
    end
  
  else
    Hessian = HessianPre;
  end
  
% $Id: admDiffFor2.m 4698 2014-09-18 20:56:20Z willkomm $
