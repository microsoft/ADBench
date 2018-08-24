% This file is part of the ADiMat runtime environment
%
% Copyright (c) 2016 Johannes Willkomm 
% Copyright (c) 2011-2014 Johannes Willkomm
%
function obj = complex(a, b)
  obj = arrdercont(a);
  if isscalar(a)
    obj.m_size = size(b);
    a.m_derivs = repmat(a.m_derivs, [1 b.m_size]);
  elseif isscalar(b)
    b.m_derivs = repmat(b.m_derivs, [1 a.m_size]);
  end
  obj.m_derivs = complex(a.m_derivs, b.m_derivs);
end
% $Id: complex.m 5104 2016-05-29 20:55:33Z willkomm $
