% function r = adimat_diff_pow_right(g_val1, val1, val2)
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_pow_right(g_val1, val1, val2)

  if isscalar(val1) && isscalar(val2)
    r = g_val1 .* val2 * val1 ^ (val2 - 1);

  elseif isscalar(val2)
    if val2 == 1
      r = g_val1;

    elseif isreal(val2) && mod(val2, 1) == 0 && val2 > 1
      r = adimat_opdiff_mult_right(g_val1, val1, (val1^(val2-1)));
      for i=1:val2-1
        tmp = adimat_opdiff_mult_left(val1^i, g_val1, val1);
        r = r + adimat_opdiff_mult_right(tmp, val1, val1^(val2-i-1));
      end

    else
      % compute a^b as expm(b * logm(a))
      [g_loga loga] = adimat_diff_logm(g_val1, val1);
      g_ex = adimat_opdiff_emult_left(val2, g_loga, loga);
      ex = val2 .* loga;
      r = adimat_diff_expm(g_ex, ex);
    
    end
  elseif isscalar(val1)
    % compute a^b as expm(b * log(a))
    [g_loga loga] = adimat_diff_log(g_val1, val1);
    g_ex = adimat_opdiff_emult_left(val2, g_loga, loga);
    ex = val2 .* loga;
    r = adimat_diff_expm(g_ex, ex);
    
  else
    error('adimat:adimat_opdiff_pow_right', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end
end
% $Id: adimat_opdiff_pow_right.m 3309 2012-06-18 09:53:52Z willkomm $
