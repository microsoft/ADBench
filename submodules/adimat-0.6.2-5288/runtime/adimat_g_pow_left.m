% function [g_z z] = adimat_g_pow_left(g_a, a, b)
%
% Compute derivative of z = a^b, matrix exponentiation. Also return
% the function result z. This a special version for constant b.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_pow_left(g_a, a, b)
  z = a^b;
  if isscalar(a) && isscalar(b)
    g_z = g_a .* b .* (a .^ (b - 1));
  elseif isscalar(b)
    if b == 1
      g_z = g_a;
    elseif isreal(b) && mod(b, 1) == 0 && b > 1
      g_z = g_a * (a^(b-1));
      for i=1:b-1
        g_z = g_z + (a^i) * g_a * (a^(b-i-1));
      end
    else
      % compute a^b as expm(b * logm(a))
      [g_loga loga] = g_logm(g_a, a);
      g_ex = b .* g_loga;
      ex = b .* loga;
      [g_z, z] = g_adimat_expm(g_ex, ex);
    end
  elseif isscalar(a)
    % compute a^b as expm(b * log(a))
    g_loga = g_a / a;
    loga = log(a);
    g_ex = b .* g_loga;
    ex = b .* loga;
    [g_z, z] = g_adimat_expm(g_ex, ex);
  else
    error('adimat:adimat_g_pow', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_g_pow_left.m 3783 2013-06-20 13:27:02Z willkomm $
