% function r = adimat_sidestack(mode, v)
%   mode=0: pop value from stack
%   mode=1: store value on stack
%   mode=2: clear stack
%   mode=3: query stack size
%   mode=4: query reserved stack size
%   mode=5: flush the stack (N/A)
%   mode=6: return the file size of the stack (N/A)
%   mode=7: return the entire stack
%
% This implementation uses a native cell array, whos size is doubled
% when needed and which is never shrunk. To clear the persistent
% variable in this function, clear this function:
%
% clear adimat_sidestack
%
% see also adimat_push, adimat_pop, adimat_clear_stack, 
%  adimat_stack_size, adimat_stack
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2010,2011 Johannes Willkomm
%
function r = adimat_sidestack(mode, v)
  persistent theStack stack_size
  switch mode
   case 0
    % pop
    if stack_size == 0
      error('adimat:runtime:stack:underrun', 'adimat: error: %s', 'stack underun');
    end
    r = theStack{stack_size};
    theStack{stack_size} = [];
    stack_size = stack_size - 1;
   case 1
    % push
    if isempty(theStack)
      theStack = {v};
      stack_size = 1;
    else
      if stack_size == length(theStack)
        theStack = [theStack cell(1, stack_size)];
      end
      stack_size = stack_size + 1;
      theStack{stack_size} = v;
    end
    r = stack_size;
   case 2
    % clear
    r = stack_size;
    theStack = {};
    stack_size = 0;
   case 3
    % size
    if isempty(stack_size), stack_size = 0; end
    r = stack_size;
   case 4
    % byte size: unknown
    r = 0;
   case 5
    % flush
    r = 0;
   case 6
    % file size: 0
    r = 0;
   case 7
    % return stack
    if isempty(theStack)
       r = { };
    else
       r = theStack(1:stack_size);
    end
   otherwise
    error('adimat:runtime:adimat_sidestack', 'unknown mode: %d', mode);
  end

% $Id: adimat_sidestack_cell2.m 4372 2014-05-29 10:24:49Z willkomm $
