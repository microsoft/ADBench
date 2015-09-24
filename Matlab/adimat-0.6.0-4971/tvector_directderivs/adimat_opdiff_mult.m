% function r = adimat_opdiff_mult(t_val1, val1, t_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_mult(t_val1, val1, t_val2, val2)
  if isscalar(val1) || isscalar(val2)
    t_res = adimat_opdiff_emult(t_val1, val1, t_val2, val2);
  else
    [ndd order nel] = size(t_val1);
    sz1 = size(val1);
    sz2 = size(val2);

    t_res = t_zeros_size([sz1(1) sz2(2)]);
  
    for i=1:ndd
      for o=1:order
        t = reshape(t_val1(i, o, :), sz1) * val2 + val1 * reshape(t_val2(i, o, :), sz2);
        for p=1:o-1
          t = t + reshape(t_val1(i, p, :), sz1) * reshape(t_val2(i, o-p, :), sz2);
        end
        t_res(i, o, :) = t(:).';
      end
    end
  end
% $Id: adimat_opdiff_mult.m 3230 2012-03-19 16:03:21Z willkomm $
