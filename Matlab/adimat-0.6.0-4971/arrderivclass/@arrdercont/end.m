% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = end(obj, k, n)
  if k < n
    res = obj.m_size(k);
  else
    res = prod(obj.m_size(k:end));
  end
end
% $Id: end.m 3862 2013-09-19 10:50:56Z willkomm $
