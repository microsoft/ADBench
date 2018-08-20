% function r = adimat_opdiff_div_left(val1, g_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_div_left(val1, g_val2, val2)
  if isscalar(val1) || isscalar(val2)
    r = adimat_opdiff_ediv_left(val1, g_val2, val2);
  else
    res = val1 / val2;
    r = d_zeros(res);
    ndd = size(g_val2, 1);
    for d=1:ndd
      dd = - res * reshape(g_val2(d,:), size(val2)) / val2;
      r(d,:) = dd(:).';
    end
  end
end
% $Id: adimat_opdiff_div_left.m 3230 2012-03-19 16:03:21Z willkomm $
