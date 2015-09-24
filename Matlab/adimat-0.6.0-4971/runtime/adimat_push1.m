% function r = adimat_push1(v)
%   store values on stack, return new size of stack
%
% see also adimat_store, adimat_pop, adimat_clear_stack, adimat_stack_size
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_push1(obj)
  r = adimat_store(1, obj);

% $Id: adimat_push1.m 4220 2014-05-16 12:57:30Z willkomm $
