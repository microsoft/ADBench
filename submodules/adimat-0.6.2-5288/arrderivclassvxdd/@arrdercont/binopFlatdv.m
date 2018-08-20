% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatdv(obj, right, handle)
%  fprintf(1, 'binopFlatdv: @%s, (%s), (%s)\n', func2str(handle), num2str(size(obj)), num2str(size(right)));
  isc_obj = prod(obj.m_size) == 1;
  dd1 = reshape(obj.m_derivs, [obj.m_size obj.m_ndd]);
  dd2 = right;
  if isc_obj
    obj.m_size = size(right);
  end
%  fprintf(1, 'bsxfun: @%s, (%s), (%s)\n', func2str(handle), num2str(size(dd1)), num2str(size(dd2)));
  obj.m_derivs = shiftedbsx(handle, dd1, dd2);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size), obj.m_ndd]);
end
% $Id: binopFlatdv.m 4469 2014-06-11 19:12:43Z willkomm $
