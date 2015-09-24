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
  obj.m_derivs = diff(obj.m_derivs, n, k+1);
  obj.m_size = computeSize(obj);
end
% $Id: diff.m 4323 2014-05-23 09:17:16Z willkomm $
