% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = ctranspose(obj)
  obj.m_derivs = permute(obj.m_derivs, [1 3 2]);
  if ~isreal(obj.m_derivs)
    obj.m_derivs = conj(obj.m_derivs);
  end
  obj.m_size = fliplr(obj.m_size);
end
% $Id: ctranspose.m 4329 2014-05-23 15:32:43Z willkomm $
