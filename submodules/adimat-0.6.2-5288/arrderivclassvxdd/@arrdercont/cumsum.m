% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = cumsum(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = cumsum(getder(obj, k), k);
  obj.m_size = computeSize(obj);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
end
% $Id: cumsum.m 4551 2014-06-15 11:44:51Z willkomm $
