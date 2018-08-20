%
% function r = adimat_stack_prefetch(n?)
%
% get/set number of buffer items to prefetch asynchronously.
% This functionality is implemented by setting the environment
% variable ADIMAT_STACK_PREFETCH. This setting applies only to those
% stack implementations with "abuffered" in their name.
%
% adimat_stack_prefetch(n) 
%   - this sets the prefetch value to n. When one buffer is filled
%   from disk with data for immediate consumption, asynchronous reads
%   are dispatched for the n preceding data blocks, if these reads are
%   not queued already.
%
% adimat_stack_prefetch()
%   - this returns the value that is currently set
%
% see also adimat_aio_init, adimat_stack, adimat_stack_buffer_size
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_stack_prefetch(sz)
  envVarName = 'ADIMAT_STACK_PREFETCH';
  if nargin > 0
    r = sprintf('%g', sz);
    setenv(envVarName, r);
  else
    r = getenv(envVarName);
  end
end

% $Id: adimat_stack_prefetch.m 3456 2012-11-06 16:39:32Z willkomm $
