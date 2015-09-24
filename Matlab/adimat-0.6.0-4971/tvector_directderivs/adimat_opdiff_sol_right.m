% function r = adimat_opdiff_sol_right(g_val1, val1, val2)
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_sol_right(g_val1, val1, val2)
  if isscalar(val1) || isscalar(val2)
    r = adimat_opdiff_esol_right(g_val1, val1, val2);
  else
    ndd = size(g_val1, 1);
    res = val1 \ val2;
    r = d_zeros(res);
    for d=1:ndd
      dd = - val1 \ reshape(g_val1(d,:), size(val1)) * res;
      r(d,:) = dd(:).';
    end
  end
end
% $Id: adimat_opdiff_sol_right.m 3133 2011-11-16 16:24:10Z willkomm $
