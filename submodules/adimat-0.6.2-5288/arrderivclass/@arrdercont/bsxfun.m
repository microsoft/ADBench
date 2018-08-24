% function obj = bsxfun(handle, x1, x2)
%
% Copyright (c) 2016 Johannes Willkomm, Johannes Willkomm Software Development
function obj = bsxfun(handle, x1, x2)
  if isobject(x1)
    obj = x1;
    obj.m_derivs = bsxfun(handle, x1.m_derivs, reshape(x2, [1 size(x2)]));
    obj.m_size = computeSize(obj);
  elseif isobject(x2)
    obj = x2;
    obj.m_derivs = bsxfun(handle, reshape(x1, [1 size(x1)]), x2.m_derivs);
    obj.m_size = computeSize(obj);
  else
  end
end