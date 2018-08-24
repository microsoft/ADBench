% @arrdercont/cross
% function obj = cross(a, b, dim)
%
% Compute cross product.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (c) 2016 Johannes Willkomm
function obj = cross(a, b, dim)
  if nargin < 3
    dim = find(size(a) == 3);
  end
  if isobject(a)
    a.m_derivs = cross(a.m_derivs, repmat(reshape(b, [1 size(b)]), [a.m_ndd 1]), dim+1);
    obj = a;
  else
    b.m_derivs = cross(repmat(reshape(a, [1 size(b)]), [b.m_ndd 1]), b.m_derivs, dim+1);
    obj = b;
  end
end