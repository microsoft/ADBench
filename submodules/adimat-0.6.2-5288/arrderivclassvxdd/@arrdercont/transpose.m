% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = transpose(obj)
  dds = permute(reshape(obj.m_derivs, [obj.m_size obj.m_ndd]), [2 1 3]);
  obj.m_derivs = reshape(dds, [prod(obj.m_size) obj.m_ndd]);
  obj.m_size = fliplr(obj.m_size);
end
% $Id: transpose.m 4173 2014-05-13 15:04:48Z willkomm $
