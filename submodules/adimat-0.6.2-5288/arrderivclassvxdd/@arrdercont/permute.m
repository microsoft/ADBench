% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = permute(obj, order)
  obj.m_derivs = permute(reshape(obj.m_derivs, [obj.m_size obj.m_ndd]), [order 1]);
  obj.m_size = obj.m_size(order);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
end
% $Id: permute.m 4336 2014-05-23 16:41:59Z willkomm $
