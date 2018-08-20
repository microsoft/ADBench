% function r = adimat_opdiff_mult_right(t_val1, val1, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_mult_right(t_val1, val1, val2)
  if isscalar(val1) || isscalar(val2)
    t_res = adimat_opdiff_emult_right(t_val1, val1, val2);
  else
    [ndd maxOrder nel] = size(t_val1);
    sz1 = size(val1);
    t_res = t_zeros_size([sz1(1) size(val2,2)]);
    for d=1:ndd
      for o=1:maxOrder
        dd = reshape(t_val1(d,o,:), sz1) * val2;
        t_res(d,o,:) = dd(:);
      end
    end
  end
% $Id: adimat_opdiff_mult_right.m 3230 2012-03-19 16:03:21Z willkomm $
