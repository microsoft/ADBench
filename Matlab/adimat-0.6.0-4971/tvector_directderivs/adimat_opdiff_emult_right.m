% function r = adimat_opdiff_emult_right(val1, t_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_emult_right(t_val1, val1, val2)
  if isscalar(val2)
    t_res = val2 .* t_val1;
  else
    [ndd maxOrder nel] = size(t_val1);
    sz2 = size(val2);
    t_val2 = reshape(val2, [1 1 sz2]);
    t_val2 = repmat(t_val2, [ndd maxOrder ones(1, length(sz2))]);
    if isscalar(val1)
      t_val1 = reshape(t_val1, [ndd maxOrder ones(1, length(sz2))]);
      t_val1 = repmat(t_val1, [1 1 sz2]);
    end
    t_res = t_val1 .* t_val2;
  end
end
% $Id: adimat_opdiff_emult_right.m 3230 2012-03-19 16:03:21Z willkomm $
