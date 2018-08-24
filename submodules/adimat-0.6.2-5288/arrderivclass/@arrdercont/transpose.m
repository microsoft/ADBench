% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = transpose(obj)
  obj.m_derivs = permute(obj.m_derivs, [1 3 2]);
  obj.m_size = fliplr(obj.m_size);
end
% $Id: transpose.m 3862 2013-09-19 10:50:56Z willkomm $
