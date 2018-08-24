% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function val = admGetDD(obj, i)
  val = reshape(obj.m_derivs(:,i), obj.m_size);
end
% $Id: admGetDD.m 4173 2014-05-13 15:04:48Z willkomm $
