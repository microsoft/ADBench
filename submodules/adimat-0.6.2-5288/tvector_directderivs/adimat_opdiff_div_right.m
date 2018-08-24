% function r = adimat_opdiff_div_right(g_val1, val1, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_opdiff_div_right(g_val1, val1, val2)
  if isscalar(val1) || isscalar(val2)
    r = adimat_opdiff_ediv_right(g_val1, val1, val2);
  else
    r = d_zeros_size([size(val1, 1) size(val2, 1)]);
    ndd = size(g_val1, 1);
    for d=1:ndd
      dd = reshape(g_val1(d,:), size(val1)) / val2;
      r(d,:) = dd(:).';
    end
  end
end
% $Id: adimat_opdiff_div_right.m 3230 2012-03-19 16:03:21Z willkomm $
