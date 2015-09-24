% function r = adimat_stack_async_io_type(name?)
%
% get/set name of the stream type underlying the stacks
% "matlab-abuffered-file" and "octave-abuffered-file". This
% functionality is implemented by setting the environment variable
% ADIMAT_ASYNC_IO_TYPE.
%
% Available stream names are:
%   - fstream: plain std::fstream (equivalent to matlab-file stack)
%   - stringstream: plain std::stringstream (equivalent to matlab-sstream stack)
%   - cfile: plain C file
%   - winfile: plain file (Windows only)
%   - mb_win: multi buffering with asynchronous I/O (Windows only)
%   - mb_aio: multi buffering with AIO (Unix only)
%   - mb_mpio: multi buffering with MPI-IO (Unix only)
%
% adimat_stack_async_io_type(name)
%   - this sets the stream name
%
% adimat_stack_async_io_type()
%   - this returns the value that is currently set
%
% see also adimat_stack, admStackOptions
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_stack_async_io_type(sz)
  envVarName = 'ADIMAT_ASYNC_IO_TYPE';
  if nargin > 0
    if isa(sz, 'char')
      setenv(envVarName, sz);
    else
      error('adimat:stack_async_io_type:inval', 'invalid argument: must be char');
    end
  else
    r = getenv(envVarName);
  end
end

% $Id: adimat_stack_async_io_type.m 3456 2012-11-06 16:39:32Z willkomm $
