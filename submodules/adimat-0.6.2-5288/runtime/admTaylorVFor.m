% function [Jacobian, varargout] = admTaylorVFor(handle, seedMatrix, varargin)
%
%  Derivatives computed with this function are precise up to machine
%  precision. The runtime depends linearly on the number of columns of
%  the seedMatrix, but only with a relativly small factor. In order to
%  compute products with the transposed Jacobian, use the function
%  admDiffRev.
%
% see also admDiffFor, admDiffRev, admDiffComplex, admDiffFD,
% admOptions, admTransform, createFullGradients,
% createSeededGradientsRev
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [TaylorCoeffs, varargout] = admTaylorVFor(handle, seedMatrix, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end
  if admOpts.checkoptions
    admCheckOptions(admOpts);
  end

  admOpts.mode = 't';
  
  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
    handle = str2func(handle);
  end
  functionPrefix = 't_';
  resultFunctionName = [functionPrefix functionName];
  
  [doTransform] = admCheckWhetherToTransformSource(admOpts, functionName, resultFunctionName);

  if doTransform
    clear(resultFunctionName);
    clocks_transformation = tic;
    fprintf(admLogFile, 'Differentiating function %s in (new) forward mode (FM) to produce\n %s...\n', ...
            functionName, resultFunctionName);
    [r] = admTransform(handle, admOpts);
    clocks_transformation = toc(clocks_transformation);
    fprintf(admLogFile, 'Differentiation took %g s.\n', clocks_transformation);
    if ~r
      error('adimat:admDiffVFor:transformationFailed', ...
            ['The transformation of %s with admTransform to produce %s has failed\n' ...
             '%s'], functionName, resultFunctionName, msg);
      return
    end
    
    admCheckTransformedFileExists(resultFunctionName);
  end

  diffFunction = str2func(resultFunctionName);
  
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

  if admOpts.clearFunctions
    clear(resultFunctionName);
  end

  admCheckNArgsFor(functionName, resultFunctionName, ...
                   nFuncArgs, nActArgs, fNargout, nActResults);
  
  clocks.evaluation = tic;
  adimat_derivclass('tvector_directderivs');

  clocks.seeding = tic;
  nCompInputs = admGetTotalNumel(funcArgs{independents});
  [seedMatrix jPattern coloring] = admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts);

  maxOrder = max(admOpts.derivOrder);
  
  [dargs{1:nActArgs}] = createSeededGradientsFor(maxOrder, seedMatrix, funcArgs{independents});

  dfargs = admMergeArgs(dargs, funcArgs, independents);
  
  nDFResults = fNargout + nActResults;
  [output{1:nDFResults}] = diffFunction(dfargs{:});
  
  actOutIndices = admDerivIndices(dependents);
  nactOutIndices = admNDerivIndices(fNargout, dependents);
  
  if admOpts.checkResultSizes > 0
    for i=actOutIndices
      d_resi = output{i};
      resi = output{i+1};
      dsz = size(d_resi);
      sz = size(resi);
      if sz(end) ~= 1
        if ~isequal(size(resi), dsz(3:end))
          warning('adimat:vector_directderivs:admDiffVFor:wrongResultSize', ...
                  'The size of the output argument is %s, but it should be %s', ...
                  mat2str(dsz), mat2str([nCompInputs maxOrder size(resi)]));
        end
      end
    end
  end
  
  dResults = {output{actOutIndices}};
  TaylorCoeffs = admTaylorArray(dResults{:});
  TaylorCoeffs = TaylorCoeffs(:,:,admOpts.derivOrder);

  varargout = output(nactOutIndices);

% $Id: admTaylorVFor.m 4584 2014-06-21 09:09:53Z willkomm $
