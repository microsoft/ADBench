% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = admSetDD(obj, i, val)
  obj.m_derivs(i,:) = val(:);
end
% $Id: admSetDD.m 3862 2013-09-19 10:50:56Z willkomm $
