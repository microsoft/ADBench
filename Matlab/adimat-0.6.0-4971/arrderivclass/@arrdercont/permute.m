% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = permute(obj, order)
  obj.m_derivs = permute(obj.m_derivs, [1 order+1]);
  msz = [obj.m_size ones(1, length(order)-length(obj.m_size))];
  obj.m_size = msz(order);
end
% $Id: permute.m 4895 2015-02-16 13:10:12Z willkomm $
