% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = complex(a, b)
  obj = arrdercont(a);
  if isscalar(a)
    obj.m_size = size(b);
  end
  obj.m_derivs = complex(a.m_derivs, b.m_derivs);
end
% $Id: complex.m 4323 2014-05-23 09:17:16Z willkomm $
