% function r = adimat_stack_num_buffers(num?)
%
% get/set the number sub buffers to split the stack memory buffer
% into. This functionality is implemented by setting the environment
% variable ADIMAT_STACK_NUM_BUFFERS. This setting applies to all stack
% implementations with "abuffered" in their name. There will be
% ADIMAT_STACK_NUM_BUFFERS buffers of size
% ADIMAT_STACK_BUFFER_SIZE/ADIMAT_STACK_NUM_BUFFERS each.
%
% The value of ADIMAT_STACK_NUM_BUFFERS will be used as the default
% value for AIO_THREADS and AIO_NUM, if ADIMAT_STACK_STREAM_TYPE is
% set to MP_AIO.

% adimat_stack_num_buffers(sz)
%   - this sets the number of buffers
%
% adimat_stack_num_buffers()
%   - this returns the current number of buffers
%
% see also adimat_stack, adimat_stack_verbosity, adimat_aio_init,
% adimat_stack_buffer_size
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_num_buffers(sz)
  envVarName = 'ADIMAT_STACK_NUM_BUFFERS';
  if nargin > 0
    r = sprintf('%g', sz);
    setenv(envVarName, r);
  else
    r = getenv(envVarName);
  end
end

% $Id: adimat_stack_num_buffers.m 3456 2012-11-06 16:39:32Z willkomm $
