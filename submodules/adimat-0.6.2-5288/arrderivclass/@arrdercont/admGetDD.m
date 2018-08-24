% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function val = admGetDD(obj, i)
  val = reshape(obj.m_derivs(i,:), obj.m_size);
end
% $Id: admGetDD.m 3862 2013-09-19 10:50:56Z willkomm $
