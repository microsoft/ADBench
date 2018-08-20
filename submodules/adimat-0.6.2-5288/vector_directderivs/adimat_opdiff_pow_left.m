% function r = adimat_diff_pow_left(val1, g_val2, val2)
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_pow_left(val1, g_val2, val2)

  if isscalar(val1) && isscalar(val2)
    r = g_val2 .* (log(val1) * val1 ^ val2);

  elseif isscalar(val2)
    % compute a^b as expm(b * logm(a))
    loga = logm(full(val1));
    g_ex = adimat_opdiff_emult_right(g_val2, val2, loga);
    ex = val2 .* loga;
    r = adimat_diff_expm(g_ex, ex);
    
  elseif isscalar(val1)
    % compute a^b as expm(b * log(a))
    loga = log(val1);
    g_ex = adimat_opdiff_emult_right(g_val2, val2, loga);
    ex = val2 .* loga;
    r = adimat_diff_expm(g_ex, ex);
  
  else
    error('adimat:adimat_opdiff_pow_left', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_opdiff_pow_left.m 3309 2012-06-18 09:53:52Z willkomm $
