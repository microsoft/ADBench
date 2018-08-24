% function [a_x] = a_funm(a_z, x)
%
% Compute adjoint of x in z = funm(x), matrix exponential, given the
% adjoint of z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [a_x] = a_funm(a_z, x, handle, options)
  if nargin < 4
    moreargs = {};
  else
    moreargs = {options};
  end
  szx = size(x);
  [partial z] = partial_funm(x, handle, eye(numel(x)), moreargs{:});
  a_x = reshape(a_z(:).' * partial, szx);
% $Id: a_funm.m 3304 2012-06-09 10:13:23Z willkomm $
