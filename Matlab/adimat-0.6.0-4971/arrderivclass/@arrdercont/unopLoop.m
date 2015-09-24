% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = unopLoop(obj, handle, varargin)
  res = cell(obj.m_ndd, 1);
  for i=1:obj.m_ndd
    dd1 = reshape(obj.m_derivs(i,:), [obj.m_size]);
    dd = handle(dd1, varargin{:});
    res{i} = reshape(full(dd), [1 size(dd)]);
  end
  obj.m_derivs = cat(1, res{:});
  obj.m_size = size(dd);
end
% $Id: unopLoop.m 4288 2014-05-21 13:35:23Z willkomm $
