% This file is part of the ADiMat runtime environment
%
% Copyright (c) 2018 Johannes Willkomm
%
function obj = ifftshift(obj, dim)
  if nargin < 2
    for k=2:ndims(obj.m_derivs)
      obj.m_derivs = ifftshift(obj.m_derivs, k);
    end
  else
    if dim < ndims(obj.m_derivs)
      obj.m_derivs = ifftshift(obj.m_derivs, dim+1);
    end
  end
end
