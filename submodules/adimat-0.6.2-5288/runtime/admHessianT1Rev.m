% function [Hessian, Jac, varargout] = ...
%    admHessianT1Rev(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Compute second order derivatives of function given by handle,
% evaluated at the arguments arg1, arg2, ..., argN and return the
% Hessian matrix, or the Hessian matrix times seedMatrix. This uses an
% overloading-over-reverse-mode (OORM) approach, i.e. it uses an OO
% class for propagating truncated taylor series, and runs the
% RM-differentiated function with it.
%
%  Options can be passed via the last argument. admHessian sets the
% options derivOrder to 2 and passes the options on to admDiffFunc.
%
% see also admDiffFor, admDiffFD, admOptions.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2014 Johannes Willkomm, Institute for Scientific Computing
%                                   TU Darmstadt
function [Hessian, Jac, varargout] = admHessianT1Rev(handle, seedMatrix, varargin)
 
% FIXME: implement this by admTaylorRev, currently this code exists
% basically twice, but first check that all optimizations are also
% over in admTaylorRev
%  [Hessian, Jac, varargout{1:nargout-2}] = admTaylorRev(handle, seedMatrix, varargin{:});
%  return

  global adjoint_tic
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end

  admOpts.mode = 'r';

  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
    handle = str2func(handle);
  end

  if ~isempty(admOpts.functionResults)
    fNargout = length(admOpts.functionResults);
  elseif ~isempty(admOpts.nargout)
    fNargout = admOpts.nargout;
  else
    fNargout = nargout(functionName);
    if fNargout < 0
      fNargout = 1;
    end
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
    clocks_transformation = tic;
    fprintf(admLogFile, 'Differentiating function %s in reverse mode (RM) to produce\n %s...\n', ...
            functionName, resultFunctionName);
    [r msg] = admTransform(handle, admOpts);
    
    if ~isempty(admOpts.functionHandles)
      funOpts = admOpts;
      % differentiation of function handles is only supported with
      % all arguments being active
      funOpts.independents = [];
      funOpts.dependents = [];
      funOpts.functionHandles = [];
      funOpts.parameters.outputMode = 'split-all';
      for fi=1:length(admOpts.functionHandles)
        argfi = admOpts.functionHandles(fi);
        argfh = varargin{argfi};
        fprintf(admLogFile, 'Differentiating function handle argument %s in reverse mode (RM) ...\n', ...
                func2str(argfh));
        admTransform(argfh, funOpts);
      end
    end
    
    times_transformation = toc(clocks_transformation);
    fprintf(admLogFile, 'Differentiation took %g s.\n', times_transformation);
    if ~r
      error('adimat:admDiffRev:transformationFailed', ...
            ['The transformation of %s with admTransform to produce %s has failed\n' ...
             '%s'], functionName, resultFunctionName);
    end
    
    admCheckTransformedFileExists(resultFunctionName);
  end

  diffFunction = str2func(resultFunctionName);
  
  functionResults = admOpts.functionResults;
  
  if isempty(functionResults)
    warning('adimat:admDiffRev:runningOriginalFunction', ...
            ['Running the function %s to obtain the size of the function results. ' ...
             'If you want to avoid this, provide a copy (or objects of the same sizes) in' ...
             ' field functionResults of the admOptions structure'], ...
            functionName);
    [functionResults{1:fNargout}] = handle(funcArgs{:});
  end
  
  nCompInputs = admTotalNumel(funcArgs{independents});
  admOpts.x_nCompInputs = nCompInputs;
  nCompOutputs = admTotalNumel(functionResults{dependents});

  [seedV, seedW, seedRev, seedMatrix, admOpts.coloring] = admMakeUserSeedMatricesHess(seedMatrix, admOpts);
  
  if isequal(seedMatrix, 1)
    ndd = nCompInputs;
  else
    ndd = size(seedMatrix, 2);
    if nCompInputs ~= size(seedMatrix, 1)
      error('adimat:hessian:seedWnotConforming', ...
            ['The number of rows of the seed ' ...
             'matrix W must be identical\nwith the total number of ' ...
             'components in the (active) function arguments.\nHowever, ' ...
             'admTotalNumel(independents) == %d and size(W, ' ...
             '1) = %d'], nCompInputs, size(seedMatrix, 1));
    end
  end

  if ischar(seedRev) && (isequal(seedRev, 's') || isequal(seedRev, 'sum'))
    seedRev = ones(1, nCompOutputs);
    nrdd = 1;
  elseif isequal(seedRev, 1)
    seedRev = eye(nCompOutputs);
    nrdd = nCompOutputs;
  else
    nrdd = size(seedRev, 1);
  end
  nrdd = size(seedRev, 1);
  if nCompOutputs ~= size(seedRev, 2)
    error('adimat:hessian:seedYnotConforming', ...
          ['The number of columns of the seed ' ...
           'matrix Y must be identical\nwith the total number of ' ...
           'components in the (active) function outputs.\nHowever, ' ...
           'admTotalNumel(dependents) == %d and size(Y, ' ...
           '2) = %d'], nCompOutputs, size(seedRev, 2));
  end

  if isempty(admOpts.taylorClassName)
    if ndd > 1
      taylorClassName = 'taylor3';
    else
      taylorClassName = 'taylor2';
    end
  else
    taylorClassName = admOpts.taylorClassName;
  end
  if admOpts.autopathchange
    if ~strcmp(adimat_adjoint, taylorClassName)
      adimat_adjoint(taylorClassName);
    end
  end
  switch taylorClassName
   case 'taylor'
    tclass = @tseries;
   case 'taylor2'
    tclass = @tseries2;
   case 'taylor3'
    tclass = @tseries2;
   otherwise
    error('no tclass')
  end
  
  if ndd > 1
    if isempty(admOpts.derivClassName)
      switch admOpts.derivClassType
       case 'cell'
        innerClassName = 'foderivclass_cell';
       case 'array'
        innerClassName = 'arrderivclass';
       otherwise
        innerClassName = 'arrderivclass';
      end
    else
      innerClassName = admOpts.derivClassName;
      switch innerClassName
       case {'opt_derivclass', 'opt_sp_derivclass'}
        warning(['using deriv class %s here is not possible here, ' ...
                 'switching to foderivclass_cell'], innerClassName);
        innerClassName = 'foderivclass_cell';
      end
    end
    if admOpts.autopathchange
      if ~strcmp(adimat_derivclass, innerClassName)
        adimat_derivclass(innerClassName);
      end
    end
%    fprintf(admLogFile('progress'), ...
%            'admHessianT1Rev: ndd=%d, using vector mode, class %s\n', ...
%            ndd, innerClassName);
    set(tclass(), 'inner', @double);
    set(tclass(), 'maxorder', 1);
    switch innerClassName
     case 'arrderivclass'
      set(tclass(), 'inner', @arrdercont);
     case 'arrderivclassvxdd'
      set(tclass(), 'inner', @arrdercont);
     case 'arrderivclassdef'
      set(tclass(), 'inner', @arrdercontdef);
%     case 'opt_derivclass'
%      set(tclass(0), 'inner', @adderivc);
%      set(g_dummy, 'NumberOfDirectionalDerivatives', ndd);
     case 'foderivclass_cell'
      set(tclass(), 'inner', @foderiv);
     otherwise
      error('no such inner class: %s', innerClassName)
    end
  else
    %    fprintf(admLogFile('progress'), 'admHessianT1Rev: ndd=%d, using scalar mode\n',ndd);
    if admOpts.autopathchange
      if ~strcmp(adimat_derivclass, 'scalar_directderivs')
        adimat_derivclass('scalar_directderivs');
      end
    end
    set(tclass(), 'inner', @double);
    set(tclass(), 'maxorder', 1);
  end

  tFuncArgs = funcArgs;
  
  if isequal(seedMatrix, 1)
    [dObjs{1:nActArgs}] = createFullGradients(funcArgs{independents});
  else
    [dObjs{1:nActArgs}] = createSeededGradientsFor(seedMatrix, funcArgs{independents});
  end
  
  for i=1:nActArgs
    indep = independents(i);
    dobj = dObjs{i};
    arg = funcArgs{indep};
    targ = tclass(arg);
    targ{2} = dobj;
    tFuncArgs{indep} = targ;
  end
  
  adjArgs = cell(1, length(dependents));
  for i=1:length(dependents)
    dep = dependents(i);
    res = functionResults{dep};
    tres = tclass(zeros(size(res)));
    adjArgs{i} = tres;
  end

  adimat_setup_stack(admOpts.stack);

  if isequal(seedV, 1)
    ndd2 = nCompInputs;
  else
    ndd2 = size(seedV, 1);
  end
  Hessian = zeros([ndd2, ndd, nrdd]);
  
  varargout = cell(fNargout, 1);
  adjResults = cell(nActArgs, 1);
             
  for i=1:nrdd
    
    offsSeed = 1;
    for j=1:length(dependents)
      dep = dependents(j);
      res = functionResults{dep};
      nel = numel(res);
      adjArgs{j}(:) = seedRev(i,offsSeed:offsSeed+nel-1);
      offsSeed = offsSeed + nel;
    end
    
    aFuncArgs = [tFuncArgs, adjArgs];
  
    adjoint_tic = tic;
    
    [adjResults{1:nActArgs}, varargout{1:fNargout}] = diffFunction(aFuncArgs{:});
    
    c2s = cellfun(@(x) x{2}, adjResults, 'uniformoutput', false);
    HStripe = admJacFor(c2s{:});
    if ~isequal(seedV, 1)
      HStripe = seedV * HStripe;
    end
    Hessian(:,:,i) = HStripe;
    
  end
  
  foderivs = cell(1, nActResults);
  for l=1:nActResults
    dep = dependents(l);
    actRes = varargout{dep};
    foderivs{l} = actRes{2};
  end
  Jac = admJacFor(foderivs{:});

  if ~isempty(admOpts.coloring)
    Jac = admUncompressJac(Jac, admOpts.JPattern, admOpts.coloring, seedW);
    Hessian = admUncompressHess(Hessian, admOpts.JPattern, admOpts.coloring, seedV, seedW);
  end

  for l=1:fNargout
    res = varargout{l};
    if isa(res, func2str(tclass))
      res = res{1};
    end
    varargout{l} = res;
  end
  
% $Id: admHessianT1Rev.m 4605 2014-07-07 14:17:45Z willkomm $
