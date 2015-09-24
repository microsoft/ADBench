% function [Jacobian, varargout] = admDiffRev(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
% see also admDiffRev.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [stack_byte_size] = admStackSize(handle, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    error('adimat:admStackSize:admOptionsMission', ...
          'the admOptions structure must be given\n');
  end

  if isempty(admOpts.functionResults)
    handle = admGetFunc(handle);
    [admOpts.functionResults{1:nargout(handle)}] = handle(funcArgs{:});
  end
  
  admOpts.parameters.printStackInfo = 1;
  admOpts.stack = 'matlab-abuffered-file';
  admOpts.parameters.stackInfoFunction = 'stack_info';

  seedMatrix = ones(1, admTotalNumel(admOpts.functionResults{admOpts.dependents}));
  
  [J r t] = admDiffRev(@forward_end, seedMatrix, funcArgs{:}, admOpts);
  
  stack_byte_size = stack_info('retrieve');
  stack_byte_size = stack_byte_size{2};
  
% $Id: admStackSize.m 4251 2014-05-18 20:25:07Z willkomm $
