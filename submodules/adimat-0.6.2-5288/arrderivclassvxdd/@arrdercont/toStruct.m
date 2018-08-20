% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function res = toStruct(obj)
  res.m_derivs = obj.m_derivs;
  res.m_ndd = obj.m_ndd;
  res.m_size = obj.m_size;
  res.className = 'arrdercont';
end
% $Id: toStruct.m 3862 2013-09-19 10:50:56Z willkomm $
