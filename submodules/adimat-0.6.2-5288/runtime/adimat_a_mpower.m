% function [a_a, a_b, z] = adimat_a_mpower(a, b, a_z)
%
% Compute adjoints a_a and a_b of z = a^b, matrix exponentiation. Also
% return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012,2014 Johannes Willkomm
%
function [a_a, a_b, z] = adimat_a_mpower(a, b, a_z)
  z = a^b;
  if isscalar(a) && isscalar(b)
    a_a = a_z .* b .* (a .^ (b - 1));
    a_b = a_z .* log(a) .* z;
  elseif isscalar(b)
    if b == 1
      a_a = a_z;
      % derivatives w.r.t. b
      loga = logm(full(a));
      expon = b .* loga;
%      z = expm(expon);
      a_expon = a_adimat_expm(expon, a_z);
      a_b = adimat_adjred(b, a_expon .* loga);
      
    elseif isreal(b) && mod(b, 1) == 0 && b > 1
      % derivatives w.r.t. a
      a_a = a_z * (a^(b-1)) .';
      for i=1:b-1
        a_a = a_a + (a^i).' * a_z * (a^(b-i-1)).';
      end
      % derivatives w.r.t. b
      % compute a^b as expm(b .* logm(a))
      loga = logm(full(a));
      expon = b .* loga;
%      z = expm(expon);
      a_expon = a_adimat_expm(expon, a_z);
      a_b = adimat_adjred(b, a_expon .* loga);
    else
      % compute a^b as expm(b .* logm(a))
      fa = full(a);
      loga = logm(fa);
      expon = b .* loga;
      z = expm(expon);

      a_expon = a_adimat_expm(expon, a_z);
      a_b = adimat_adjred(b, a_expon .* loga);
      a_loga = b .* a_expon;
      a_a = a_logm(a_loga, fa);
    end
  elseif isscalar(a)
    % compute a^b as expm(b .* log(a))
    loga = log(a);
    expon = b .* loga;
    z = expm(expon);
    
    a_expon = a_adimat_expm(expon, a_z);
    a_b = a_expon .* loga;
    a_loga = adimat_adjred(loga, b .* a_expon);
    a_a = a_loga ./ a;
  else
    error('adimat:adimat_g_pow', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_a_mpower.m 4149 2014-05-11 11:34:39Z willkomm $
  