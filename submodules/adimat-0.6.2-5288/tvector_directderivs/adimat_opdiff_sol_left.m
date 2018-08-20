% function r = adimat_opdiff_sol_left(val1, g_val2, val2)
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_sol_left(val1, g_val2, val2)
  if isscalar(val1) || isscalar(val2)
    r = adimat_opdiff_esol_left(val1, g_val2, val2);
  else
    ndd = size(g_val2, 1);
    r = d_zeros_size([size(val1, 2), size(val2, 2)]);
    for d=1:ndd
      dd = val1 \ reshape(g_val2(d,:), size(val2));
      r(d,:) = dd(:).';
    end
  end
end
% $Id: adimat_opdiff_sol_left.m 3133 2011-11-16 16:24:10Z willkomm $
