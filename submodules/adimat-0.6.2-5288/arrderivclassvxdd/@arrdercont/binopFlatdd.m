% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatdd(obj, right, handle)
  isc_obj = prod(obj.m_size) == 1;
  dd1 = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
  dd2 = reshape(right.m_derivs, [right.m_size right.m_ndd]);
  if isc_obj
    obj.m_size = right.m_size;
  end
  obj.m_derivs = shiftedbsx(handle, dd1, dd2);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size), obj.m_ndd]);
end
% $Id: binopFlatdd.m 4469 2014-06-11 19:12:43Z willkomm $
