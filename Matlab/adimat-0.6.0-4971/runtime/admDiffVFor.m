% function [Jacobian, varargout] = admDiffVFor(handle, seedMatrix, varargin)
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
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiffVFor(handle, seedMatrix, varargin)
  
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

  admOpts.mode = 'f';
  
  if any(admOpts.derivOrder < 1) || any(admOpts.derivOrder > 1)
    error('adimat:admDiffVFor:wrongDerivOrder', ['invalid derivative ' ...
                        'order %s: must be 1'], mat2str(admOpts.derivOrder));
  end

  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
    handle = str2func(handle);
  end
  functionPrefix = 'd_';
  resultFunctionName = [functionPrefix functionName];
  
  [doTransform] = admCheckWhetherToTransformSource(admOpts, ...
                                                    functionName, resultFunctionName);

  if doTransform
    clear(resultFunctionName);
    fprintf(admLogFile, 'Differentiating function %s in (new) forward mode (FM) to produce\n %s...\n', ...
            functionName, resultFunctionName);
    times_transformation = tic;
    [r, ttm] = admTransform(handle, admOpts);
    times_transformation = toc(times_transformation);
    fprintf(admLogFile, 'Differentiation took %g s.\n', times_transformation);
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
  
  if ~strcmp(adimat_derivclass, 'vector_directderivs')
    adimat_derivclass('vector_directderivs');
  end
  
  nCompInputs = admTotalNumel(funcArgs{independents});
  seedW = seedMatrix;
  if ~isnumeric(seedW)
    seedW = 1;
  end
  [seedMatrix coloring jPattern] = admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts);

  if isequal(seedMatrix, 1)
    [dargs{1:nActArgs}] = createFullGradients(funcArgs{independents});
  else
    [dargs{1:nActArgs}] = createSeededGradientsFor(seedMatrix, funcArgs{independents});
  end

  dfargs = admMergeArgs(dargs, funcArgs, independents);
  
  nDFResults = fNargout + nActResults;
  [output{1:nDFResults}] = diffFunction(dfargs{:});
  
  actOutIndices = admDerivIndices(dependents);
  nactOutIndices = admNDerivIndices(fNargout, dependents);
  % nactOutIndices = setdiff(1:nDFResults, actOutIndices);
  
  if admOpts.checkResultSizes > 0
    for i=actOutIndices
      d_resi = output{i};
      resi = output{i+1};
      dsz = size(d_resi);
      sz = size(resi);
      if sz(end) ~= 1
        if ~isequal(size(resi), dsz(2:end))
          warning('adimat:wrongResultSize', ...
                  'The size of the output argument is %s, but it should be %s', ...
                  mat2str(dsz), mat2str([nCompInputs size(resi)]));
        end
      end
    end
  end
  
  dResults = {output{actOutIndices}};
  Jacobian = admJacFor(dResults{:});
  if ~isempty(jPattern)
    Jacobian = admUncompressJac(Jacobian, jPattern, coloring, seedW);
  end

  varargout = output(nactOutIndices);

% $Id: admDiffVFor.m 4833 2014-10-13 07:11:09Z willkomm $
