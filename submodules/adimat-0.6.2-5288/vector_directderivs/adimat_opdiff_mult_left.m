% function d_res = adimat_diff_mult_left(val1, g_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val2 = adimat_opdiff_mult_left(val1, d_val2, val2)
  if isscalar(val1) || isscalar(val2)
    d_val2 = adimat_opdiff_emult_left(val1, d_val2);
  else
    
    [m n] = size(val1);
    [ndd n p] = size(d_val2);
    
    res = zeros(ndd, m, p);
    At = val1.';
    for k=1:p
      res(:, :, k) = d_val2(:, :, k) * At;
    end
    d_val2 = res;
    
  end
% $Id: adimat_opdiff_mult_left.m 4355 2014-05-28 11:10:28Z willkomm $
