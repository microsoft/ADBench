% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = flipdim(obj, k)
  obj.m_derivs = flipdim(obj.m_derivs, k+1);
end
% $Id: flipdim.m 4323 2014-05-23 09:17:16Z willkomm $
