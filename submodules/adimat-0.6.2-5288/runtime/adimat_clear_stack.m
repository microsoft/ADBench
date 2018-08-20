%
% function r = adimat_clear_stack()
%  clear stack
%
% see also adimat_store, adimat_stack, adimat_stack_size, adimat_flush_stack
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_clear_stack()
  r = adimat_store(2, 0);

% $Id: adimat_clear_stack.m 1764 2010-02-25 19:05:10Z willkomm $
