% function [TCsRev, TCsFor, varargout] = admTaylorRev(handle, seedMatrix, varargin)
%
% Evaluate derivatives in forward-over-reverse mode, by running the RM
% differentiated code with the tseries class for univariate Taylor
% series in FM.
% 
% see also admDiffRev, tseries, admOptions.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2010-2014 Johannes Willkomm
%
function [TCsRev, TCsFor, varargout] = admTaylorRev(handle, seedMatrix, varargin)
  
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
  admOpts.checkoptions = false;

  admOpts.mode = 'r';

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

  if ~isempty(admOpts.functionResults)
    fNargout = length(admOpts.functionResults);
  elseif ~isempty(admOpts.nargout)
    fNargout = admOpts.nargout;
  else
    fNargout = nargout(functionName);
  end

  functionResults = admOpts.functionResults;
  
  if isempty(functionResults)
    warning('adimat:admTaylorRev:runningOriginalFunction', ...
            ['Running the function %s to obtain the size of the function results. ' ...
             'If you want to avoid this, provide a copy (or objects of the same sizes) in' ...
             ' field functionResults of the admOptions structure'], ...
            functionName);
    clocks_feval = tic;
    [functionResults{1:fNargout}] = handle(funcArgs{:});
    clocks_feval = toc(clocks_feval);
    warning('adimat:admDiffRev:runningOriginalFunction', ...
            'Running the function %s took %g s', ...
            functionName, clocks_feval);
  end
  
  admOpts.x_nCompInputs = admGetTotalNumel(funcArgs{independents});
  admOpts.x_nCompOutputs = admTotalNumel(functionResults{dependents});

  clocks.seeding = tic;
  
  [~, seedMatrix, seedRev] = admMakeUserSeedMatricesHess(seedMatrix, admOpts);
  
  if isequal(seedMatrix, 1)
    seedMatrix = eye(admOpts.x_nCompInputs);
  end
  if ischar(seedRev) && (strcmp(seedRev, 's') || strcmp(seedRev, 'sum'))
    seedRev = ones(1, admOpts.x_nCompOutputs);
  elseif isequal(seedRev, 1)
    seedRev = eye(admOpts.x_nCompOutputs);
  end
  
  nddFor = size(seedMatrix, 2);
  nddRev = size(seedRev, 1);

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
        [fhr fhmsg] = admTransform(argfh, funOpts);
      end
    end
    
    clocks_transformation = toc(clocks_transformation);
    fprintf(admLogFile, 'Differentiation took %g s.\n', clocks_transformation);
    if ~r
      error('adimat:admDiffRev:transformationFailed', ...
            ['The transformation of %s with admTransform to produce %s has failed\n' ...
             '%s'], functionName, resultFunctionName);
      return
    end
    
    admCheckTransformedFileExists(resultFunctionName);
  end

  diffFunction = str2func(resultFunctionName);
  

  maxOrder = max(admOpts.derivOrder);
    
  if isempty(admOpts.taylorClassName)
    if nddFor > 1
      taylorClassName = 'taylor3';
    else
      taylorClassName = 'taylor2';
    end
  else
    taylorClassName = admOpts.taylorClassName;
  end
  if ~strcmp(adimat_adjoint, taylorClassName)
    adimat_adjoint(taylorClassName);
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
  
  if nddFor > 1
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
    if ~strcmp(adimat_derivclass, innerClassName)
      adimat_derivclass(innerClassName);
    end
%    fprintf(admLogFile('progress'), ...
%            'admHessianT1Rev: ndd=%d, using vector mode, class %s\n', ...
%            ndd, innerClassName);
    set(tclass(), 'inner', @double);
    set(tclass(), 'maxorder', maxOrder);
    switch innerClassName
     case 'arrderivclass'
      set(tclass(), 'inner', @arrdercont);
      set(arrdercont(), 'ndd', nddFor);
     case 'arrderivclassvxdd'
      set(tclass(), 'inner', @arrdercont);
      set(arrdercont(), 'ndd', nddFor);
     case 'arrderivclassdef'
      set(tclass(), 'inner', @arrdercontdef);
      set(arrdercontdef(), 'ndd', nddFor);
%     case 'opt_derivclass'
%      set(tclass(0), 'inner', @adderivc);
%      set(g_dummy, 'NumberOfDirectionalDerivatives', ndd);
     case 'foderivclass_cell'
      set(tclass(), 'inner', @foderiv);
      foderiv.option('ndd', nddFor);
     otherwise
      error('no such inner class: %s', innerClassName)
    end
  else
    %    fprintf(admLogFile('progress'), 'admHessianT1Rev: ndd=%d, using scalar mode\n',ndd);
    if ~strcmp(adimat_derivclass, 'scalar_directderivs')
      adimat_derivclass('scalar_directderivs');
    end
    set(tclass(), 'inner', @double);
    set(tclass(), 'maxorder', maxOrder);
  end

  tFuncArgs = funcArgs;
  
  [dObjs{1:nActArgs}] = createSeededGradientsFor(seedMatrix, funcArgs{independents});
  
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

  TCsRev = zeros([admOpts.x_nCompInputs, nddFor, nddRev, maxOrder]);
  
  for d=1:nddRev

    offs = 1;
    
    for i=1:length(dependents)
      dep = dependents(i);
      res = functionResults{dep};
      nel = admTotalNumel(res);
  
      adjArgs{i}(1:nel) = seedRev(d,offs:offs+nel-1);
     
      offs = offs + nel;
    end
    
    aFuncArgs = {tFuncArgs{:}, adjArgs{:}};
    
    [adjResults{1:nActArgs}, varargout{1:fNargout}] = diffFunction(aFuncArgs{:});
    
    % first order coeffs
%    cs = cellfun(@(x) x{1}(:), adjResults, 'uniformoutput', false);
%    TStripe = admJacFor(cs{:});
%    TCsRev(d,o,:,:) = reshape(TStripe, [admOpts.x_nCompInputs, nddFor]);
    
    for o=2:maxOrder+1
      cs = cellfun(@(x) x{o}, adjResults, 'uniformoutput', false);
      TStripe = admJacFor(cs{:});
      TCsRev(:,:,d,o-1) = reshape(TStripe, [admOpts.x_nCompInputs, nddFor]);
    end
    
  end

  % remove second (nddFor) and/or third (nddRev) and/or fourth (order) dimension if 1
  % => result is Hessian, if nddRev == 1 and order == 1
  if length(size(TCsRev)) > 3
    TCsRev = admSqueezeDim(TCsRev, 4);
  end
  if length(size(TCsRev)) > 2
    TCsRev = admSqueezeDim(TCsRev, 3);
  end
%  TCsRev = admSqueezeDim(TCsRev, 2);

  TCsFor = admTaylorArray(varargout{dependents});
  TCsFor = TCsFor(:,:,admOpts.derivOrder);

  for l=1:fNargout
    res = varargout{l};
    if isa(res, func2str(tclass))
      res = res{1};
      if isa(res, 'foderiv')
        res = res{1};
      end
    end
    varargout{l} = res;
  end
  
% $Id: admTaylorRev.m 4720 2014-09-19 10:59:12Z willkomm $
