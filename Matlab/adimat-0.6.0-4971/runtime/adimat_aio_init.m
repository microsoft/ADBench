% function r = adimat_aio_init(nThreads?, nBuffers?, idleTime?, direct?)
%
% get/set some parameters of the aio.h API. This functionality is
% implemented by setting the environment variables AIO_THREADS,
% AIO_NUM, and AIO_IDLE_TIME, respectively. The variable's values are
% used to call the non standard function aio_init, which is available
% e.g. on GNU implementations. These settings apply only to those
% stack implementations with "abuffered" in their name.
%
% adimat_aio_init(nThreads, nBuffers?, idleTime?, oDirect?)
%   - this sets the parameters
%
% adimat_aio_init()
%   - this returns the values that are currently set in a cell array
%
% adimat_aio_init('clear')
%   - clear all four variables
%
% Parameters can either be float scalars or empty, in which case the
% default values will be used. The default value for AIO_THREADS and
% AIO_NUM is ADIMAT_STACK_NUM_BUFFERS, the default for AIO_IDLE_TIME
% is 10, and the default for ABUF_ODIRECT is 0 (off).
%
% see also adimat_stack, adimat_stack_num_buffers,
% adimat_stack_verbosity
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_aio_init(numThreads, numBuffers, idleTime, direct)
  envVarName1 = 'AIO_THREADS';
  envVarName2 = 'AIO_NUM';
  envVarName3 = 'AIO_IDLE_TIME';
  envVarName4 = 'ABUF_ODIRECT';
  if nargin > 0
    if isa(numThreads, 'char') && strcmp(numThreads, 'clear')
      setenv(envVarName1, '');
      setenv(envVarName2, '');
      setenv(envVarName3, '');
      setenv(envVarName4, '');
      r = {'', '', '', ''};
      return
    end
    r1 = sprintf('%g', numThreads);
    setenv(envVarName1, r1);
    if nargin > 1
      r2 = sprintf('%g', numBuffers);
      setenv(envVarName2, r2);
    end
    if nargin > 2
      r3 = sprintf('%g', idleTime);
      setenv(envVarName3, r3);
    end
    if nargin > 3
      r3 = sprintf('%g', direct);
      setenv(envVarName4, r3);
    end
  end
  r = {getenv(envVarName1), getenv(envVarName2), getenv(envVarName3), getenv(envVarName4)};
end

% $Id: adimat_aio_init.m 3456 2012-11-06 16:39:32Z willkomm $
