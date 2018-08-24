% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = ifft(obj, varargin)
  mode = 'nonsymmetric';
  if nargin > 1 && ischar(varargin{end})
    mode = varargin{end};
    varargin = varargin(1:end-1);
  end
  if length(varargin) < 1
    n = [];
  else
    n = varargin{1};
  end
  if length(varargin) < 2
    k = adimat_first_nonsingleton(obj);
  else
    k = varargin{2};
  end
  if admIsOctave()
    modeArgs = {};
  else
    modeArgs = {mode};
  end
  if admIsOctave() && k+1 > length(size(obj.m_derivs))
    % note: this concerns only trailing dimensions > 2 which are
    % singleton. hence repmat to n works
    obj.m_derivs = repmat(obj.m_derivs, adimat_repind(length(size(obj.m_derivs)), k+1,n))./n;
    obj.m_size(k) = n;
  else
    obj.m_derivs = ifft(obj.m_derivs, n, k+1, modeArgs{:});
    obj.m_size = computeSize(obj);
  end
end
% $Id: ifft.m 4829 2014-10-13 07:06:33Z willkomm $
