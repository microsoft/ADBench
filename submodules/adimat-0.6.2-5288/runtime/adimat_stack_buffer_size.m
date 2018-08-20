% function r = adimat_stack_buffer_size(sz?)
%
% get/set the size of the memory buffer used by the stack. This
% functionality is implemented by setting the environment variable
% ADIMAT_STACK_BUFFER_SIZE. This setting applies to all stack
% implementations with "file" in their name.
%
% adimat_stack_buffer_size(sz)
%   - this sets the buffer size to sz bytes
%
% adimat_stack_buffer_size()
%   - this returns the value that is currently set
%
% see also adimat_stack, adimat_stack_verbosity, adimat_aio_init
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_buffer_size(sz)
  envVarName = 'ADIMAT_STACK_BUFFER_SIZE';
  if nargin > 0
    r = sprintf('%g', sz);
    setenv(envVarName, r);
  else
    r = getenv(envVarName);
  end
end

% $Id: adimat_stack_buffer_size.m 3456 2012-11-06 16:39:32Z willkomm $
