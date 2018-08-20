% function obj = adimat_init(template, value)
%
% Create object with value of the same type as template.
%
% Copyright (C) 2014 Johannes Willkomm
%
function obj = adimat_init(template, value)
  if isa(template, 'tseries')
    obj = tseries(value);
  else
    obj = value;
  end
% $Id: adimat_init.m 4007 2014-01-13 10:14:54Z willkomm $
