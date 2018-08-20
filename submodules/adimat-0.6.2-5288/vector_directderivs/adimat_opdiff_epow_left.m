% function d_res = adimat_opdiff_epow_left(val1, d_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val2 = adimat_opdiff_epow_left(val1, d_val2, val2)
  ndd = size(d_val2, 1);
  factor2 = log(val1) .* val1 .^ val2;
  if any(val1 == 0)
    warning('adimat:power:argZero', '%s', ...
            'x .^ y is evaluated with x == 0, and we need the derivative w.r.t. y');
    factor2(isinf(factor2)) = adimat_missing_derivative_value();
  end
  d_val2 = bsxfun(@times, d_val2, reshape(full(factor2), [1 size(factor2)]));
% $Id: adimat_opdiff_epow_left.m 4963 2015-03-03 11:56:24Z willkomm $
