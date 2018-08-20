% function r = adimat_stack_verbosity(level?)
%
% get/set name stack implementations verbosity level. This
% functionality is implemented by setting the environment variable
% ADIMAT_STACK_VERBOSITY. This setting applies to all stack
% implementations written in C/C++, i.e. with either "matlab" or
% "octave" in their name.
%
% adimat_stack_verbosity(level)
%   - this sets the verbosity level
%
% adimat_stack_verbosity()
%   - this returns the value that is currently set
%
% see also adimat_stack, adimat_stack_buffer_size, adimat_aio_init
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_verbosity(sz)
  envVarName = 'ADIMAT_STACK_VERBOSITY';
  if nargin > 0
    if isa(sz, 'char')
      [num] = str2num(sz);
      % if ~success
      %   error('adimat:adimat_stack_verbosity:stringNotANumber', ...
      %         'Size given as string ''%s'', which is not a valid number!', ...
      %         sz);
      % end
      sz = num;
    end
    r = sprintf('%g', sz);
    setenv(envVarName, r);
  else
    r = getenv(envVarName);
  end
end

% $Id: adimat_stack_verbosity.m 3456 2012-11-06 16:39:32Z willkomm $
