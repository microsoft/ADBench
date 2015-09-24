function [g_r r]= g_abs(g_p, p)
% G_ABS -- Compute the derivative g_p according to the value of p
% g_r is the negative of g_p if p is less than zero,
% g_r is g_p if p is greater than zero, and
% if p is zero then an error is issued, because abs is not differentiable
% at zero.
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  r = abs(p);
  if isreal(p)
    sig_p= sign(p);
    if (any(find(sig_p==0.0)))
      warning('adimat:abs:argZero', '%s', 'g_abs(g_p, p) not defined for p==0.0');
      sig_p(sig_p == 0) = 1;
    end
    g_r= sig_p.* g_p;
  else
    eq0 = r == 0;
    if any(eq0(:))
      warning('adimat:abs:argZero', '%s', 'g_abs(g_p, p) not defined for p==0.0');
    end
    g_r = g_p;
    g_r(~eq0) = (real(p(~eq0)) .* call(@real, g_p(~eq0)) ...
                 + imag(p(~eq0)) .* call(@imag, g_p(~eq0))) ./ r(~eq0);
    g_r(eq0) = g_zeros([1 1]) + adimat_missing_derivative_value();
  end

% vim:sts=3:
% $Id: g_abs.m 4834 2014-10-13 08:24:55Z willkomm $
