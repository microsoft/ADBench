% function r = adimat_pop()
%  pop value from stack
%
% see also adimat_push, adimat_store, adimat_clear_stack, adimat_stack_size
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2014 Johannes Willkomm
%
function varargout = adimat_pop()
  npop = max(1, nargout);
  varargout = cell(npop, 1);
  for i=1:npop
    obj = adimat_store(0, 0);
    varargout{i} = obj;
  end

% $Id: adimat_pop.m 4220 2014-05-16 12:57:30Z willkomm $
