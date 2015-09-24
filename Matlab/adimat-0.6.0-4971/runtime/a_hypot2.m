% function [a_y] = a_hypot(a_z, x, y)
%
% Compute adjoint of y in z = hypot(x, y), given the adjoint of z.
%
% see also a_zeros, a_mean
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function [a_y z] = a_hypot(a_z, x, y)
  % t = x.^2 + y.^2
  % z = sqrt(t)
  z = hypot(x, y);
  a_t = 0.5 .* a_z ./ z;
  a_y = adimat_adjred(y, a_t .* 2 .* y);
% $Id: a_hypot2.m 3561 2013-04-09 08:28:47Z willkomm $
