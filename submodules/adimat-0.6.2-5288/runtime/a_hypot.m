% function [a_x a_y] = a_hypot(a_z, x, y)
%
% Compute adjoints of z = hypot(x, y), where a_z is the adjoint of z.
%
% see also a_zeros, a_mean
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function [a_x, a_y] = a_hypot(a_z, x, y)
  t = x .^2 + y .^2;
  z = sqrt(t);
  eq0 = t == 0;
  if any(eq0(:))
    warning('adimat:hypot:argZero', '%s', 'a_hypot(a_z, x, y) not defined for x and y both 0');
  end
  a_t = 0.5 .* a_z;
  a_t(~eq0) = a_t(~eq0) ./ z(~eq0);
  a_t(eq0) = a_zeros(0) + adimat_missing_derivative_value();
  a_x = a_t .* 2 .* x;
  a_y = a_t .* 2 .* y;
% $Id: a_hypot.m 4834 2014-10-13 08:24:55Z willkomm $
