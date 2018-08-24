% function t_res = adimat_opdiff_emult(t_val1, val1, t_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [t_res res] = adimat_opdiff_emult(t_val1, val1, t_val2, val2)
  [ndd order nel] = size(t_val1);
  sz1 = size(val1);
  sz2 = size(val2);

  if isscalar(val2)
    t_res = t_val1;
  else
    t_res = t_val2;
  end
  
  v1 = reshape(val1, [1 1 prod(sz1)]);
  if isscalar(val1)
    v1 = repmat(v1, [1 1 prod(sz2)]);
    t_val1 = repmat(t_val1, [1 1 prod(sz2)]);
  end
  v1 = repmat(v1, [ndd 1 1]);

  v2 = reshape(val2, [1 1 prod(sz2)]);
  if isscalar(val2)
    v2 = repmat(v2, [1 1 prod(sz1)]);
    t_val2 = repmat(t_val2, [1 1 prod(sz1)]);
  end
  v2 = repmat(v2, [ndd 1 1]);
  
  for o=1:order
    t = t_val1(:, o, :) .* v2 + v1 .* t_val2(:, o, :);
    for k=1:o-1
      t = t + t_val1(:, k, :) .* t_val2(:, o-k, :);
    end
    t_res(:, o, :) = t;
  end

  if nargout > 1
    res = val1 .* val2;
  end
  
% $Id: adimat_opdiff_emult.m 3230 2012-03-19 16:03:21Z willkomm $
