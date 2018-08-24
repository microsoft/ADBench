% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = admSetDD(obj, i, val)
  obj.m_derivs(:,i) = val(:);
end
% $Id: admSetDD.m 4173 2014-05-13 15:04:48Z willkomm $
