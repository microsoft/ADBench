% function [g_z z] = adimat_g_pow_right(a, g_b, b)
%
% Compute derivative of z = a^b, matrix exponentiation. Also return
% the function result z. This a special version for constant a.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_pow_right(a, g_b, b)
  z = a^b;
  if isscalar(a) && isscalar(b)
    g_z = g_b .* log(a) .* z;
  elseif isscalar(b)
    if b == 1
      loga = logm(full(a));
      g_ex = g_b .* loga;
      ex = loga;
      g_z = g_adimat_expm(g_ex, ex);
    elseif isreal(b) && mod(b, 1) == 0 && b > 1
      % derivatives w.r.t. b
      % compute a^b as expm(b * logm(a))
      loga = logm(full(a));
      g_ex = g_b .* loga;
      ex = b .* loga;
      g_z = g_adimat_expm(g_ex, ex);
      % [V D] = eig(a);
      % lambda = diag(D);
      % g_z = V * call(@diag, lambda .^ b .* log(lambda) .* g_b) * inv(V);
    else
      % compute a^b as expm(b * logm(a))
      loga = logm(a);
      g_ex = g_b .* loga;
      ex = b .* loga;
      [g_z, z] = g_adimat_expm(g_ex, ex);
    end
  elseif isscalar(a)
    % compute a^b as expm(b * log(a))
    loga = log(a);
    g_ex = g_b .* loga;
    ex = b .* loga;
    [g_z, z] = g_adimat_expm(g_ex, ex);
  else
    error('adimat:adimat_g_pow', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_g_pow_right.m 3783 2013-06-20 13:27:02Z willkomm $
