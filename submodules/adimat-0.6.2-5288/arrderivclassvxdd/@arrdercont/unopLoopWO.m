% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = unopLoopWO(handle, wo, varargin)
  obj = varargin{wo};
  res = cell(obj.m_ndd, 1);
  sz = obj.m_size;
  for i=1:obj.m_ndd
    dd1 = reshape(obj.m_derivs(:,i), sz);
    dd = handle(varargin{1:wo-1}, dd1, varargin{wo+1:end});
    res{i} = dd(:);
  end
  obj.m_derivs = cat(2, res{:});
  obj.m_size = size(dd);
end
% $Id: unopLoopWO.m 4796 2014-10-08 10:37:06Z willkomm $
