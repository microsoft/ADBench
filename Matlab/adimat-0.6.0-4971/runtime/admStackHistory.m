% function [Jacobian, varargout] = admDiffRev(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
% see also admDiffRev.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [J varargout t handles] = admStackHistory(handle, seedMatrix, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    error('adimat:admStackSize:admOptionsMission', ...
          'the admOptions structure must be given\n');
  end

  fName = handle; 
  if isa(fName, 'function_handle'), fName = func2str(handle); end
  
  if isempty(admOpts.functionResults)
    handle = admGetFunc(handle)
    fName = func2str(handle);
    [admOpts.functionResults{1:nargout(fName)}] = handle(funcArgs{:});
  end
  
  admOpts.parameters.printStackInfo = 3;
  admOpts.infoStack = 'save';

  adimat_sidestack(2);

  if ~isempty(admOpts.functionResults)
    fNargout = length(admOpts.functionResults);
  elseif ~isempty(admOpts.nargout)
    fNargout = admOpts.nargout;
  else
    fNargout = nargout(functionName);
  end
  
  ran = false;
  try
    [J varargout{1:fNargout} t] = admDiffRev(handle, seedMatrix, funcArgs{:}, admOpts);
    ran = true;
  catch
    J = [];
    [varargout{1:fNargout}] = deal([]);
    t = admTimes;
    % hopefully the crash was just because stack null was used
  end
  
  t0 = tic;
  handle(funcArgs{:});
  tF = toc(t0);
  
  stackInfo = adimat_sidestack(7);
  if ~ran
    stackInfo = {stackInfo{:} stackInfo{end-1:-1:1}};
  end
  
  stackName = admOpts.stack;

  sFName = sprintf('stackhist-%s-%s.mat', adimat_version(4), stackName);
  num = 0;
  while exist(sFName)
    num = num + 1;
    sFName = sprintf('stackhist-%s-%s-%d.mat', adimat_version(4), ...
                     stackName, num);
  end
  
  save('-mat', sFName, 'stackInfo', 'admOpts', 'tF');
  handles = sFName;
  
  if ~admOpts.dontPlot
    handles = admPlotStackHistory(stackInfo, admOpts, tF);
  end

% $Id: admStackHistory.m 4251 2014-05-18 20:25:07Z willkomm $
