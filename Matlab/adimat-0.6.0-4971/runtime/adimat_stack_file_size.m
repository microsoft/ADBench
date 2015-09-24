%
% function r = adimat_stack_file_size()
%  return size of the file the stack implementation uses, if any,
%  otherwise return 0
%
% see also adimat_store, adimat_stack, adimat_clear_stack, adimat_size, adimat_byte_size
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_stack_file_size()
  r = adimat_store(6, 0);

% $Id: adimat_stack_file_size.m 1764 2010-02-25 19:05:10Z willkomm $
