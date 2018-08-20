% function d_res = adimat_opdiff_div_right(g_val1, val1, val2)
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_res = adimat_opdiff_div_right(d_val1, val1, val2)
  szv2 = size(val2);
  if isscalar(val2) || (isscalar(val1) && length(szv2) > 2)
    d_res = adimat_opdiff_ediv_right(d_val1, val1, val2);
  else
    ndd = size(d_val1, 1);
    szv1 = size(val1);
    d_res = d_zeros_size([size(val1, 1) size(val2, 1)]);
    for d=1:ndd
      dd = reshape(d_val1(d,:), szv1) / val2;
      d_res(d,:) = dd(:).';
    end
  end
end
% $Id: adimat_opdiff_div_right.m 3232 2012-03-19 21:22:33Z willkomm $
