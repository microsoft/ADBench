% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = mean(obj, k)
  if nargin < 2
    k = adimat_first_nonsingleton(obj);
  end
  if admIsOctave() && k+1 > length(size(obj.m_derivs))
  else
    obj.m_derivs = mean(obj.m_derivs, k+1);
    obj.m_size = computeSize(obj);
  end
end
% $Id: mean.m 4829 2014-10-13 07:06:33Z willkomm $
