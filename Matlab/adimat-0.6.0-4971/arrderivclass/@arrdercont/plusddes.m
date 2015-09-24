% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = plusddes(obj, right)
  obj.m_derivs = obj.m_derivs + right.m_derivs;
end
% $Id: plusddes.m 4585 2014-06-22 08:06:21Z willkomm $
