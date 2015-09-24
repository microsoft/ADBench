% function d_res = adimat_opdiff_epow_right(d_val1, val1, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val1 = adimat_opdiff_epow_right(d_val1, val1, val2)
  ndd = size(d_val1, 1);
  factor1 = full(val2 .* val1 .^ (val2 - 1));
  if any((val2 - 1) < 0 & val1 == 0)
    warning('adimat:power:argZero', '%s', ...
            'x .^ y is evaluated with y < 0 and x == 0');
    factor1(isinf(factor1)) = adimat_missing_derivative_value();
  end
  d_val1 = bsxfun(@times, d_val1, reshape(factor1, [1 size(factor1)]));
end
% $Id: adimat_opdiff_epow_right.m 4779 2014-10-06 13:10:21Z willkomm $
