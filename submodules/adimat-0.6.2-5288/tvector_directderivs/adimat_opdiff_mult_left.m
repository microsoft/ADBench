% function r = adimat_diff_mult_left(val1, t_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_mult_left(val1, t_val2, val2)
  if isscalar(val1) || isscalar(val2)
    t_res = adimat_opdiff_emult_left(val1, t_val2, val2);
  else
    [ndd maxOrder nel] = size(t_val2);
    sz2 = size(val2);
    t_res = t_zeros_size([size(val1, 1), sz2(2)]);
    for d=1:ndd
      for o=1:maxOrder
        tmp = val1 * reshape(t_val2(d,o,:), sz2);
        t_res(d,o,:) = tmp(:).';
      end
    end
  end
end
% $Id: adimat_opdiff_mult_left.m 3230 2012-03-19 16:03:21Z willkomm $
