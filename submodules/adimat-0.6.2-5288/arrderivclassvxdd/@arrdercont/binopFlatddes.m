% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = binopFlatddes(obj, right, handle)
  obj.m_derivs = handle(obj.m_derivs, right.m_derivs);
end
% $Id: binopFlatddes.m 4497 2014-06-13 12:00:25Z willkomm $
