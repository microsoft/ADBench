% function [g_z z] = adimat_g_pow(g_a, a, g_b, b)
%
% Compute derivative of z = a^b, matrix exponentiation. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [g_z z] = adimat_g_pow(g_a, a, g_b, b)
  z = a^b;
  if isscalar(a) && isscalar(b)
    g_z = g_a .* b .* (a .^ (b - 1));
    g_z = g_z + g_b .* log(a) .* z;
  elseif isscalar(b)
    if b == 1
      loga = logm(full(a));
      g_ex = g_b .* loga;
      ex = loga;
      g_zb = g_adimat_expm(g_ex, ex);
      g_z = g_a + g_zb;
    
    elseif isreal(b) && mod(b, 1) == 0 && b > 1
      % derivatives w.r.t. a
      g_z = g_a * (a^(b-1));
      for i=1:b-1
        g_z = g_z + (a^i) * g_a * (a^(b-i-1));
      end
      % + derivatives w.r.t. b
      % compute a^b as expm(b .* logm(a))
      loga = logm(full(a));
      g_ex = g_b .* loga;
      ex = b .* loga;
      g_zb = g_adimat_expm(g_ex, ex);
      % + derivatives w.r.t. b
%      [V D] = eig(a);
%      lambda = diag(D);
      g_z = g_z + g_zb;
    else
      % compute a^b as expm(b .* logm(a))
      [g_loga loga] = g_logm(g_a, a);
      g_ex = b * g_loga + g_b .* loga;
      ex = b .* loga;
      [g_z, z] = g_adimat_expm(g_ex, ex);
    end
  elseif isscalar(a)
    % compute a^b as expm(b .* log(a))
    g_loga = g_a / a;
    loga = log(a);
    g_ex = b .* g_loga + g_b .* loga;
    ex = b .* loga;
    [g_z, z] = g_adimat_expm(g_ex, ex);
  else
    error('adimat:adimat_g_pow', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_g_pow.m 3953 2013-10-18 09:36:55Z willkomm $
  