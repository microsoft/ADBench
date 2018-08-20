% function r = adimat_setup_stack(stackOptions)
%
% setup runtime environment for using stack given by
% stackOptions.stackName.
%
% see also adimat_stack, adimat_info_stack, adimat_stack_verbosity,
% adimat_stack_buffer_size, adimat_stack_num_buffers,
% adimat_stack_prefetch, adimat_stack_async_io_type,
% adimat_stack_mpi_file_info, adimat_aio_init, adimat_stack_dir_name,
% adimat_stack_file_name
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function r = adimat_setup_stack(stackOptions)
  persistent lastOptions

  if isequal(lastOptions, stackOptions)
    return
  end
  
%  clear adimat_store;
  lastOptions = stackOptions;
  
  if ~isempty(stackOptions.name)
    if ~strcmp(adimat_stack, stackOptions.name)
      adimat_stack(stackOptions.name);
    end
  end
  if ~isempty(stackOptions.infoStackName)
    adimat_info_stack(stackOptions.infoStackName);
  end
  if strfind(adimat_stack(), 'abuffered')
    adimat_aio_init(stackOptions.aio_threads, stackOptions.aio_num, stackOptions.aio_idle_time, stackOptions.odirect);
    adimat_stack_prefetch(stackOptions.prefetchBlocks);
    adimat_stack_num_buffers(stackOptions.numBuffers);
    if ~isempty(stackOptions.asyncIOType)
      adimat_stack_async_io_type(stackOptions.asyncIOType);
    end
    adimat_stack_mpi_file_info(stackOptions.mpiFileInfo);
  end
  adimat_stack_buffer_size(stackOptions.bufferSize);
  adimat_stack_verbosity(stackOptions.verbose);
  if ~isempty(stackOptions.dirName)
    adimat_stack_dir_name(stackOptions.dirName);
  end
  if ~isempty(stackOptions.fileName)
    adimat_stack_file_name(stackOptions.fileName);
  end
  
end

% $Id: adimat_setup_stack.m 4245 2014-05-18 12:48:54Z willkomm $
