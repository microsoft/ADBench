% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = plus(obj, right)
  obj = binopFlatdv(obj, right, @plus);
end
% $Id: plusdv.m 4392 2014-06-03 07:41:31Z willkomm $
