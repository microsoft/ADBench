% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = diff(obj, n, k)
  if nargin < 2
    n = 1;
  end
  if nargin < 3
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = diff(getder(obj, k), n, k);
  obj.m_size = computeSize(obj);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
end
% $Id: diff.m 4551 2014-06-15 11:44:51Z willkomm $
