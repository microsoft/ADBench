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

    if val2 == 1
      r = g_val2 .* log(val1) .* val1;

    elseif isreal(val2) && mod(val2, 1) == 0 && val2 > 1
      if ~all(g_val2 == 0)
        warning('adimat:adimat_opdiff_pow_left', '%s', ...
                ['Differentiation of A^b, where A is a square matrix and b is integer > 1, ' ...
                 'will not consider derivatives w.r.t. b.']);
      end

      r = d_zeros(val1);

    else
      error('adimat:adimat_opdiff_pow_left', '%s', ...
            ['Differentiation of A^b, where A is a square matrix and b is scalar, ' ...
             'but not an integer > 1, is not supported.']);
    end
  elseif isscalar(val1)
    error('adimat:adimat_opdiff_pow_left', '%s', ...
          ['Differentiation of a^B, where a is scalar and B is a ' ...
           'square matrix, is not supported.']);
  else
    error('adimat:adimat_opdiff_pow_left', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_opdiff_pow_left.m 3140 2011-11-28 14:23:22Z willkomm $
