% function [Jacobian, varargout] = admDiffDD(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
% This function is deprecated and replaced by admDiffFD.
%
% see also admDiffFD, admDiffFor, admDiffRev.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiffDD(handle, seedMatrix, varargin)
  
  times = admTimes();
  clocks = times;
  clocks.total = datenum(clock());
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
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

  nCompInputs = admGetTotalNumel(funcArgs{independents});
  
  clocks.evaluation = datenum(clock());

  if isequal(seedMatrix, 1)
    seedMatrix = eye(nCompInputs);
  end
  
  ch = admOpts.fdStep;
  
  switch admOpts.fdMode
   case {'c', 'central', 'centralized'}
    [Jacobian, varargout{1:fNargout+1}] = ...
        admComputeDerivCentralDD(handle, seedMatrix, independents, ...
                                 dependents, fNargout, -ch, admOpts.functionEvaluation, ...
                                 funcArgs{:});
   case {'l', 'left', 'neg', 'negative'}
    [Jacobian, varargout{1:fNargout+1}] = ...
        admComputeDerivDD(handle, seedMatrix, independents, ...
                          dependents, fNargout, -ch, funcArgs{:});
   case {'r', 'right', 'pos', 'positive'}
    [Jacobian, varargout{1:fNargout+1}] = ...
        admComputeDerivDD(handle, seedMatrix, independents, ...
                          dependents, fNargout, ch, funcArgs{:});
   otherwise
    error('adimat:admDiffDD:unknownDDMode', ...
          'Mode switch ''%s'' for DD mode is not supported', admOpts.fdMode)
  end
  
  times.feval = varargout{end};
  times.evaluation = (datenum(clock) - clocks.evaluation) *24*3600;
  times.total = (datenum(clock) - clocks.total) *24*3600;

  varargout{fNargout+1} = times;
% $Id: admDiffDD.m 4251 2014-05-18 20:25:07Z willkomm $
