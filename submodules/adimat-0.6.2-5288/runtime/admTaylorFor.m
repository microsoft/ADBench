% function [Jacobian, varargout] = admTaylorFor(handle, seedMatrix, varargin)
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
% Copyright 2014 Johannes Willkomm
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [TaylorCoeffs, varargout] = admTaylorFor(handle, seedMatrix, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
    if admOpts.checkoptions
      admCheckOptions(admOpts);
    end
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end
  admOpts.checkoptions = false;

  if ~isa(handle, 'function_handle')
    handle = str2func(handle);
  end
  
  if isempty(admOpts.nargout)
    functionName = func2str(handle);
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

  nCompInputs = admTotalNumel(funcArgs{independents});
  [seedMatrix jPattern coloring] = admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts);

  if isequal(seedMatrix, 1)
    ndd = nCompInputs;
  else
    ndd = size(seedMatrix, 2);
  end
  
  maxOrder = max(admOpts.derivOrder);
  
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
      innerClassName = 'arrderivclass';
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
    set(tclass(), 'maxorder', maxOrder);
    switch innerClassName
     case 'arrderivclass'
      set(tclass(), 'inner', @arrdercont);
      set(arrdercont(), 'ndd', ndd);
     case 'arrderivclassvxdd'
      set(tclass(), 'inner', @arrdercont);
      set(arrdercont(), 'ndd', ndd);
     case 'arrderivclassdef'
      set(tclass(), 'inner', @arrdercontdef);
      set(arrdercontdef(), 'ndd', ndd);
%     case 'opt_derivclass'
%      set(tclass(0), 'inner', @adderivc);
%      set(g_dummy, 'NumberOfDirectionalDerivatives', ndd);
     case 'foderivclass_cell'
      set(tclass(), 'inner', @foderiv);
      foderiv.option('ndd', ndd);
     otherwise
      error('no such inner class: %s', innerClassName)
    end
  else
    % fprintf(admLogFile('main'), 'admTaylorFor: using scalar mode\n');
    if admOpts.autopathchange
      adimat_derivclass('scalar_directderivs');
    end
    set(tclass(), 'inner', @double);
    set(tclass(), 'maxorder', maxOrder);
  end

  if isequal(seedMatrix, 1)
    [dargs{1:nActArgs}] = createFullGradients(funcArgs{independents});
  else
    [dargs{1:nActArgs}] = createSeededGradientsFor(seedMatrix, funcArgs{independents});
  end

  for i=1:nActArgs
    indep = independents(i);
    targ = tclass(funcArgs{indep});
    targ{2} = dargs{i};
    funcArgs{indep} = targ;
  end
  
  [output{1:fNargout}] = handle(funcArgs{:});
  
  dResults = output(dependents);
  TaylorCoeffs = admTaylorArrayInt(maxOrder, ndd, dResults{:});

  varargout = output;
  for i=1:length(output)
    if strcmp(class(output{i}), 'tseries2')
      varargout{i} = output{i}{1};
    else
      varargout{i} = output{i};
    end
  end

% $Id: admTaylorFor.m 4986 2015-05-11 15:27:11Z willkomm $
