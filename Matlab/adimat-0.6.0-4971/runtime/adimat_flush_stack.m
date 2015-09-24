%
% function r = adimat_flush_stack()
%  flush stack - if the stack implmentation uses a file, write all
%  stack contents to that file
%
% see also adimat_stack, adimat_stack_size, adimat_clear_stack
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_flush_stack()
  r = adimat_store(5, 0);

% $Id: adimat_flush_stack.m 2891 2011-05-10 13:59:33Z willkomm $
