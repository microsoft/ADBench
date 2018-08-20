% function func = admGetFunc(nameOrHandle)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function func = admGetFunc(nameOrHandle)
  if isa(nameOrHandle, 'char')
    func = str2func(nameOrHandle);
  elseif isa(nameOrHandle, 'function_handle')
    func = nameOrHandle;
  else
    func = [];
  end

% $Id: admGetFunc.m 2990 2011-06-16 14:27:52Z willkomm $
