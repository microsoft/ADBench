% function r = adimat_store(mode, v)
%
% This implementation does nothing.
%
% see also adimat_push, adimat_pop, adimat_clear_stack, 
%  adimat_stack_size, adimat_stack
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_store(mode, v)
  persistent nitems
  r = 0;
  switch mode
   case 0, nitems = nitems - 1;
   case 1, nitems = nitems + 1;
   case 2, nitems = 0;
   case 3, if isempty(nitems), nitems = 0; end, r = nitems;
    %  case 4, r = 0;
    %  case 5
    %  case 6, r = 0;
    %  case 7
    %  otherwise
    %   error('adimat:runtime:stacks:adimat_store', 'unknown mode: %d', mode);
  end

% $Id: adimat_store.m 3393 2012-09-10 11:09:57Z willkomm $
