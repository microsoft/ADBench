% function a_x = a_abs(a_z, x)
%
% Compute adjoint of z = abs(x), where a_z is the adjoint of z.
%
% see also a_zeros, a_mean
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt

function a_x = a_abs(a_z, x)
  if isreal(x)
    lt0 = x < 0;
    if any(x == 0)
      warning('adimat:abs:argZero', '%s', 'a_abs(a_z, x) not defined for x==0.0');
    end
    a_x = a_z;
    a_x(lt0) = -a_x(lt0);
  else
    % FM: 
    %    g_z = (real(x) .* call(@real, g_x) + imag(x) .* call(@imag, g_x)) ./ z;
    % f:
    %    r = real(x)
    %    i = imag(x)
    %    t = r .^2 + i .^2
    %    z = sqrt(t)
    [a_r a_i] = a_hypot(a_z, real(x), imag(x));
    a_xr = call(@real, a_r);
    a_xi = call(@imag, a_i);
    a_x = calln(@complex, a_xr, a_xi);
  end
% $Id: a_abs.m 4834 2014-10-13 08:24:55Z willkomm $
