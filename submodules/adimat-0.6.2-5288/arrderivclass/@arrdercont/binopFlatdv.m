% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatdv(obj, right, handle)
%  fprintf(1, 'binopFlatdv: @%s, (%s), (%s)\n', func2str(handle), num2str(size(obj)), num2str(size(right)));
  dd1 = obj.m_derivs;
  if isscalar(right)
    obj.m_derivs = handle(obj.m_derivs, right);
  else
    dd2 = reshape(full(right), [1 size(right)]);
    if prod(obj.m_size) == 1
      obj.m_size = size(right);
    end
    obj.m_derivs = bsxfun(handle, dd1, dd2);
  end
%  fprintf(1, 'bsxfun: @%s, (%s), (%s)\n', func2str(handle), num2str(size(dd1)), num2str(size(dd2)));
end
% $Id: binopFlatdv.m 4585 2014-06-22 08:06:21Z willkomm $
