% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = unopLoop(obj, handle, varargin)
  res = cell(obj.m_ndd, 1);
  sz = obj.m_size;
  for i=1:obj.m_ndd
    dd1 = reshape(obj.m_derivs(:,i), sz);
    dd = handle(dd1, varargin{:});
    res{i} = dd(:);
  end
  obj.m_derivs = cat(2, res{:});
  obj.m_size = size(dd);
end
% $Id: unopLoop.m 4173 2014-05-13 15:04:48Z willkomm $
