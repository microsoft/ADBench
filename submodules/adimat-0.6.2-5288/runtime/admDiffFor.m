% function [Jacobian, varargout] = admDiffFor(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Compute first order derivatives of function given by handle,
%  evaluated at the arguments arg1, arg2, ..., argN. This works by
%  running a version of the function differentiated in forward mode
%  (FM) of automatic differentiation (AD). If not present, or when the
%  admOptions argument changes, this differentiated function is
%  created automatically using the admTransform command.
%
%  The derivatives are returned in the form of a so called Jacobian
%  matrix, which contains the derivatives of each result parameter of
%  the function given by handle, w.r.t. to all of the function
%  parameters.
%
%  When seedMatrix is equal to 1, then the full Jacobian is computed
%  and returned. Otherwise the matrix product
%
%       Jacobian * seedMatrix 
%
%  is computed and returned, but WITHOUT actually computing the full
%  jacobian matrix. Setting seedMatrix equal to 1 is an abbreviation
%  for using eye(K), where K is the total number of components in the
%  function arguments. Giving a column vector of length K as
%  seedMatrix is an efficient way of computing matrix-vector products
%  with the Jacobian.
%
%  The arguments following seedMatrix are the function arguments. They
%  are given to the differentiated function unmodified. They are also
%  used to created input derivatives for the differentiated
%  function. The derivative of the function given by handle is
%  evaluated at these arguments.
%
%  When the last argument is a struct with a field named admopts, this
%  argument is used by this function to obtain certain
%  parameters. These are explained in the documentation of function
%  admOptions.
%
%  Derivatives computed with this function are precise up to machine
%  precision. The runtime depends linearly on the number of columns of
%  the seedMatrix. In order to compute products with the transposed
%  Jacobian, use the function admDiffRev.
%
% see also admDiffRev, admDiffVFor, admTransform, createFullGradients,
% createSeededGradientsFor, admJacFor, admOptions, adimat_derivclass,
% admDiffComplex, admDiffFD.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiffFor(handle, seedMatrix, varargin)
  
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
  
  if any(admOpts.derivOrder < 1) || any(admOpts.derivOrder > 2)
    error('adimat:admDiffFor:wrongDerivOrder', ['invalid derivative ' ...
          'order %s: all must be >=1 and <=2'], mat2str(admOpts.derivOrder));
  end
  
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

  if find(admOpts.derivOrder == 2)
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
  else
    functionPrefix = admOpts.parameters.funcprefix;
    resultFunctionName = [functionPrefix functionName];
  end
  
  [doTransform] = admCheckWhetherToTransformSource(admOpts, functionName, resultFunctionName);

  if doTransform
    if find(admOpts.derivOrder == 2)
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
    else
      clear(resultFunctionName);
      times_transformation = tic;
      fprintf(admLogFile, 'Differentiating function %s in forward mode (FM) to produce\n %s...\n', ...
              functionName, resultFunctionName);
      [r msg] = admTransform(handle, admOpts);
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
  end

  diffFunction = str2func(resultFunctionName);
  
  nCompInputs = admTotalNumel(funcArgs{independents});
  
  nDFResults = fNargout + nActResults;
  actOutIndices = admDerivIndices(dependents);
  
  if admOpts.checknargs && ~admOpts.parameters.secondorderfwd
    % check does not work with 2nd order yet
    admCheckNArgsFor(functionName, resultFunctionName, ...
                     nFuncArgs, nActArgs, fNargout, nActResults);
  end
  
  seedW = seedMatrix;
  if ~isnumeric(seedW)
    seedW = 1;
  end
  [seedMatrix coloring jPattern] = ...
      admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts);

  if isequal(seedMatrix, 1)
    ndd = nCompInputs;
  else
    ndd = size(seedMatrix, 2);
  end
  
  admSelectDerivClass(ndd, admOpts);

  if admOpts.clearFunctions
    admClearFunctions(functionName, 'g_');
  end
  
  [Jacobian, varargout{1:fNargout}] = ...
      admComputeDerivFor(diffFunction, seedMatrix, independents, ...
                         dependents, fNargout, ...
                         admOpts, funcArgs{:});

  if ~isempty(jPattern)
    Jacobian = admUncompressJac(Jacobian, jPattern, coloring, seedW);
  end
  
% $Id: admDiffFor.m 4646 2014-09-12 21:51:54Z willkomm $
