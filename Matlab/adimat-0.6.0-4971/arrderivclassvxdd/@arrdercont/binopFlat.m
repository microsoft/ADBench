% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlat(obj, right, handle)
  obj_sz = size(obj);
  isc_obj = prod(obj_sz) == 1;
  isc_right = prod(size(right)) == 1;
  if isobject(obj)
    if isc_obj
      dd1 = reshape(obj.m_derivs, [ones(1,length(size(right))) obj.m_ndd]);
    else
      dd1 = reshape(obj.m_derivs, [obj_sz obj.m_ndd]);
    end
    if isobject(right)
      if isc_right
        dd2 = reshape(right.m_derivs, [ones(1,length(obj_sz)) right.m_ndd]);
      else
        dd2 = reshape(right.m_derivs, [right.m_size right.m_ndd]);
      end
      if isc_obj
        obj.m_size = right.m_size;
      end
    else
      dd2 = right;
      if isc_obj
        obj.m_size = size(right);
      end
    end
  else
    dd1 = obj;
    if isc_right
      dd2 = reshape(right.m_derivs, [ones(1,length(obj_sz)) right.m_ndd]);
      right.m_size = size(obj);
    else
      dd2 = reshape(right.m_derivs, [right.m_size right.m_ndd]);
    end
    obj = right;
  end
  obj.m_derivs = shiftedbsx(handle, dd1, dd2);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size), obj.m_ndd]);
end
% $Id: binopFlat.m 4819 2014-10-09 15:42:29Z willkomm $
