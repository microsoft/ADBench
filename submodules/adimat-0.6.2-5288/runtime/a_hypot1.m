% function [a_x] = a_hypot(a_z, x, y)
%
% Compute adjoint of x in z = hypot(x, y), given the adjoint of z.
%
% see also a_zeros, a_mean
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function [a_x z] = a_hypot(a_z, x, y)
  % t = x.^2 + y.^2
  % z = sqrt(t)
  z = hypot(x, y);
  a_t = 0.5 .* a_z ./ z;
  a_x = adimat_adjred(x, a_t .* 2 .* x);
% $Id: a_hypot1.m 3561 2013-04-09 08:28:47Z willkomm $
