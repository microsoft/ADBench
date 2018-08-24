% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = ipermute(obj, order)
  obj.m_derivs = ipermute(obj.m_derivs, [1 order+1]);
  obj.m_size(order) = obj.m_size;
end
% $Id: ipermute.m 4323 2014-05-23 09:17:16Z willkomm $
