% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function [obj, mi] = min(obj)
  [mv, mi] = min(obj.m_derivs{1});
  for i=1:obj.m_ndd
    obj.m_derivs{i} = obj.m_derivs{i}(mi);
  end
end
% $Id: min.m 3862 2013-09-19 10:50:56Z willkomm $
