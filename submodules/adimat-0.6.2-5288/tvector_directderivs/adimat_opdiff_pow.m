% function r = adimat_opdiff_pow(t_val1, val1, t_val2, val2)
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_pow(t_val1, val1, t_val2, val2)

  if isscalar(val1) && isscalar(val2)
    t_res = adimat_opdiff_epow(t_val1, val1, t_val2, val2);

  elseif isscalar(val2)

    if val2 == 1
      t_res = t_val1 + t_val2 .* log(val1) .* val1;

    elseif isreal(val2) && mod(val2, 1) == 0 && val2 > 1
      if ~all(t_val2(:) == 0)
        warning('adimat:adimat_opdiff_pow', '%s', ...
                ['Differentiation of A^b, where A is a square matrix and b is integer > 1, ' ...
                 'will not consider derivatives w.r.t. b.']);
      end

      t_res = adimat_opdiff_mult_right(t_val1, val1, (val1^(val2-1)));
      for i=1:val2-1
        tmp = adimat_opdiff_mult_left(val1^i, t_val1, val1);
        t_res = t_res + adimat_opdiff_mult_right(tmp, val1, val1^(val2-i-1));
      end

    else
      error('adimat:adimat_opdiff_pow', '%s', ...
            ['Differentiation of A^b, where A is a square matrix and b is scalar, ' ...
             'but not an integer > 1, is not supported.']);
    end
  elseif isscalar(val1)
    error('adimat:adimat_opdiff_pow', '%s', ...
          ['Differentiation of a^B, where a is scalar and B is a ' ...
           'square matrix, is not supported.']);
  else
    error('adimat:adimat_opdiff_pow', '%s', ...
          'A^B, where both X and Y are matrices, is not allowed in Matlab');
  end

% $Id: adimat_opdiff_pow.m 3230 2012-03-19 16:03:21Z willkomm $
