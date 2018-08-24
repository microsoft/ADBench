% This file is part of the ADiMat runtime environment
%
% Copyright (c) 2018 Johannes Willkomm
%
function obj = fftshift(obj, dim)
  if nargin < 2
    for k=2:ndims(obj.m_derivs)
      obj.m_derivs = fftshift(obj.m_derivs, k);
    end
  else
    if dim < ndims(obj.m_derivs)
      obj.m_derivs = fftshift(obj.m_derivs, dim+1);
    end
  end
end
