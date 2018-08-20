% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = ctranspose(obj)
  dds = permute(reshape(obj.m_derivs, [obj.m_size obj.m_ndd]), [2 1 3]);
  if ~isreal(dds)
    dds = conj(dds);
  end
  obj.m_derivs = reshape(dds, [prod(obj.m_size) obj.m_ndd]);
  obj.m_size = fliplr(obj.m_size);
end
% $Id: ctranspose.m 4329 2014-05-23 15:32:43Z willkomm $
