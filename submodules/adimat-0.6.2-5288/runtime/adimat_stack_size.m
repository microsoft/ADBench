%
% function r = adimat_stack_size()
%  return size of stack
%
% see also adimat_store, adimat_stack, adimat_clear_stack, adimat_byte_size, adimat_file_size
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_stack_size()
  r = adimat_store(3, 0);

% $Id: adimat_stack_size.m 1764 2010-02-25 19:05:10Z willkomm $
