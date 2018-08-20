% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatdd(obj, right, handle)
  dd1 = obj.m_derivs;
  dd2 = right.m_derivs;
  if prod(obj.m_size) == 1
    obj.m_size = right.m_size;
  end
  obj.m_derivs = bsxfun(handle, dd1, dd2);
end
% $Id: binopFlatdd.m 4392 2014-06-03 07:41:31Z willkomm $
