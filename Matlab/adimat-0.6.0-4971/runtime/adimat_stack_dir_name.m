% function r = adimat_stack_dir_name(name?)
%
% get/set directory name for the stack data file. This functionality
% is implemented by setting the environment variable
% ADIMAT_STACK_DIR. This setting applies to all stack implementations
% with "file" in their name.
%
% adimat_stack_dir_name(level)
%   - this sets the dir name
%
% adimat_stack_dir_name()
%   - this returns the current dir name
%
% see also adimat_stack, admStackOptions
%
% This dir is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_dir_name(sz)
  envVarName = 'ADIMAT_STACK_DIR';
  if nargin > 0
    if isa(sz, 'char')
      setenv(envVarName, sz);
    else
      error('adimat:stack_dir_name:inval', 'invalid argument: must be char');
    end
  else
    r = getenv(envVarName);
  end
end

% $Id: adimat_stack_dir_name.m 3456 2012-11-06 16:39:32Z willkomm $
