% function [Jacobian, varargout] = admDiffRev(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Compute first order derivatives of function given by handle,
%  evaluated at the arguments arg1, arg2, ..., argN. This works by
%  running a version of the function differentiated in reverse mode
%  (RM) of automatic differentiation (AD). If not present, or when the
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
%       seedMatrix * Jacobian
%
%  is computed and returned, but WITHOUT actually computing the full
%  jacobian matrix. Setting seedMatrix equal to 1 is an abbreviation
%  for using eye(K), where K is the total number of components in the
%  function arguments. Giving a row vector of length K as seedMatrix
%  is an efficient way of computing vector-matrix products with the
%  Jacobian. 
%
%  The arguments following seedMatrix are the function arguments. They
%  are given to the differentiated function unmodified. The derivative
%  of the function given by handle is evaluated at these arguments.
%
%  When the last argument is a struct with a field named admopts, this
%  argument is used by this function to obtain certain
%  parameters. These are explained in the documentation of function
%  admOptions.
%
%  This function needs to know the shape and dimension of the function
%  results. Therefore it will run the original function once to obtain
%  this information. To avoid this initial running of the function,
%  the user can specify the field functionResults of the admOptions
%  struct to be a cell array of objects of the same type and dimension
%  as the function results. These objects do not have to contain the
%  actual function's result, they can be all zero instead.
%
%  It may also be the case that the function returns nargout>1
%  parameters, but the user is only interested in the first k of
%  these. If this is the case set the field nargout of the admOptions
%  struct to k, or provide only that many items in the field
%  functionResults.
%
%  Derivatives computed with this function are precise up to machine
%  precision. The runtime depends linearly on the number of rows of
%  the seedMatrix. In order to compute products of the form jacobian
%  times seedMatrix, use the forward mode functions.
%
% see also admDiffFor, admDiffVFor, admTransform, createFullGradients,
% createSeededGradientsFor, admJacFor, admOptions, adimat_derivclass,
% admDiffComplex, admDiffFD.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiffRev(handle, seedMatrix, varargin)
  
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

  admOpts.mode = 'r';

  if any(admOpts.derivOrder < 1) || any(admOpts.derivOrder > 1)
    error('adimat:admDiffRev:wrongDerivOrder', ['invalid derivative ' ...
                        'order %s: must be 1'], mat2str(admOpts.derivOrder));
  end

  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
    handle = str2func(handle);
  end
  functionPrefix = 'a_';
  resultFunctionName = [functionPrefix functionName];

  [doTransform] = admCheckWhetherToTransformSource(admOpts, functionName, resultFunctionName);

  if doTransform
    clear(resultFunctionName);
    times_transformation = tic;
    fprintf(admLogFile, 'Differentiating function %s in reverse mode (RM) to produce\n %s...\n', ...
            functionName, resultFunctionName);
    r = admTransform(handle, admOpts);
    
    if ~isempty(admOpts.functionHandles)
      funOpts = admOpts;
      % differentiation of function handles is only supported with
      % all parameters (of the function handles) being active
      funOpts.independents = [];
      funOpts.dependents = [];
      funOpts.functionHandles = [];
      funOpts.parameters.outputMode = 'split-all';
      for fi=1:length(admOpts.functionHandles)
        argfi = admOpts.functionHandles(fi);
        argfh = varargin{argfi};
        fprintf(admLogFile, 'Differentiating function handle argument %s in reverse mode (RM) ...\n', ...
                func2str(argfh));
        fhr = admTransform(argfh, funOpts);
      end
    end
    
    times_transformation = toc(times_transformation);
    fprintf(admLogFile, 'Differentiation took %g s.\n', times_transformation);
    if ~r
      error('adimat:admDiffRev:transformationFailed', ...
            ['The transformation of %s with admTransform to produce %s has failed\n' ...
             '%s'], functionName, resultFunctionName);
    end
    
    admCheckTransformedFileExists(resultFunctionName);
  end

  diffFunction = str2func(resultFunctionName);
  
  if ~isempty(admOpts.functionResults)
    fNargout = length(admOpts.functionResults);
  elseif ~isempty(admOpts.nargout)
    fNargout = admOpts.nargout;
  else
    fNargout = nargout(functionName);
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

  functionResults = admOpts.functionResults;
  
  if isempty(functionResults)
    warning('adimat:admDiffRev:runningOriginalFunction', ...
            ['Running the function %s to obtain the size of the function results. ' ...
             'If you want to avoid this, provide a copy (or objects of the same sizes) in' ...
             ' field functionResults of the admOptions structure'], ...
            functionName);
    times_feval = tic;
    [functionResults{1:fNargout}] = handle(funcArgs{:});
    times_feval = toc(times_feval);
    warning('adimat:admDiffRev:runningOriginalFunction', ...
            'Running the function %s took %g s', ...
            functionName, times_feval);
  end

  nCompOutputs = admGetTotalNumel(functionResults{dependents});

  if admOpts.clearFunctions
    clear(resultFunctionName);
  end

  if admOpts.checknargs
    admCheckNArgsRev(functionName, resultFunctionName, nFuncArgs, ...
                     nActArgs, fNargout, nActResults, ...
                     length(admOpts.functionHandles));
  end

  seedV = seedMatrix;
  if ~isnumeric(seedV)
    seedV = 1;
  end
  [seedMatrix coloring jPattern] = ...
      admMakeSeedMatrixRev(seedMatrix, nCompOutputs, admOpts);

  if isequal(seedMatrix, 1)
    ndd = nCompOutputs;
  else
    ndd = size(seedMatrix, 1);
  end
  admSelectDerivClass(ndd, admOpts);
  a = 'default';
  if admOpts.autopathchange
    if ~strcmp(adimat_adjoint, a)
      adimat_adjoint(a);
    end
  end
  adimat_setup_stack(admOpts.stack);

  % Reverse mode: clear the global variables indicating whether or
  % not global adjoint variables have been initialized
  clear('-global', 'init_a_*');
  clear adimat_stack_info;
  
  global adjoint_tic
  adjoint_tic = tic;
  
  [Jacobian, varargout{1:fNargout}] = ...
      admComputeDerivRev(diffFunction, seedMatrix, independents, ...
                         dependents, functionResults, admOpts, funcArgs{:});

  if ~isempty(functionResults)
    for i=1:fNargout
      if ~isequal(size(functionResults{i}), size(varargout{i}))
        error('adimat:admDiffRev:functionResultsWrong', '%s',...
              ['The functionResults that you specified are different in ' ...
               'size from those actually returned by the function']);
      end
    end
  end
  
  if ~isempty(jPattern)
    Jacobian = admUncompressJac(Jacobian .', jPattern, coloring, seedV.') .';
  end

% $Id: admDiffRev.m 4794 2014-10-07 20:49:05Z willkomm $
