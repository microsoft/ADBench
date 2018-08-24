% function r = adimat_push(v)
%   store values on stack, return new size of stack
%
% see also adimat_store, adimat_pop, adimat_clear_stack, adimat_stack_size
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2014 Johannes Willkomm
%
function r = adimat_push(varargin)
  for i=1:nargin
    obj = varargin{i};
    r = adimat_store(1, obj);
  end

% $Id: adimat_push.m 4220 2014-05-16 12:57:30Z willkomm $
