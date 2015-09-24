% function d_res = adimat_opdiff_epow(d_val1, val1, d_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val1 = adimat_opdiff_epow(d_val1, val1, d_val2, val2)
  factor1 = val2 .* val1 .^ (val2 - 1);
  if any((val2 - 1) < 0 & val1 == 0)
    warning('adimat:power:argZero', '%s', ...
            'x .^ y is evaluated with y < 0 and x == 0');
    factor1(isinf(factor1)) = adimat_missing_derivative_value();
  end
  factor2 = log(val1) .* val1 .^ val2;
  if any(val1 == 0)
    warning('adimat:power:argZero', '%s', ...
            'x .^ y is evaluated with x == 0, and we need the derivative w.r.t. y');
    factor2(isinf(factor2)) = adimat_missing_derivative_value();
  end

  d_val1 = bsxfun(@times, d_val1, reshape(full(factor1), [1 size(factor1)])) + ...
           bsxfun(@times, d_val2, reshape(full(factor2), [1 size(factor2)]));
  
% $Id: adimat_opdiff_epow.m 4963 2015-03-03 11:56:24Z willkomm $
