% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = sum(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  obj.m_derivs = sum(obj.m_derivs, k+1);
  obj.m_size = computeSize(obj);
end
% $Id: sum.m 4268 2014-05-20 08:28:26Z willkomm $
