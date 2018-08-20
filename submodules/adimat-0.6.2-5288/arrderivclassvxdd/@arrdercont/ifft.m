% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = ifft(obj, n, k, varargin)
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
  obj.m_derivs = ifft(getder(obj, k), n, k, varargin{:});
  obj.m_size = computeSize(obj);
  obj.m_derivs = reshape(obj.m_derivs, [prod(obj.m_size) obj.m_ndd]);
end
% $Id: ifft.m 4764 2014-10-03 16:17:18Z willkomm $
