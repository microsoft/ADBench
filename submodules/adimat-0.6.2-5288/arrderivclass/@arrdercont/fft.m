% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = fft(obj, n, k)
  if nargin < 2
    n = [];
  end
  if nargin < 3
    k = adimat_first_nonsingleton(obj);
  end
  if admIsOctave() && k+1 > length(size(obj.m_derivs))
    % note: this concerns only trailing dimensions > 2 which are
    % singleton. hence repmat to n works
    obj.m_derivs = repmat(obj.m_derivs, adimat_repind(length(size(obj.m_derivs)), k+1,n));
    obj.m_size(k) = n;
  else
    obj.m_derivs = fft(obj.m_derivs, n, k+1);
    obj.m_size = computeSize(obj);
  end
end
% $Id: fft.m 4829 2014-10-13 07:06:33Z willkomm $
