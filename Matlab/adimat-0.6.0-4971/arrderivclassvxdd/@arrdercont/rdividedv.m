% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = rdividedv(obj, right)
  obj = binopFlatdv(obj, 1 ./ right, @times);
end
% $Id: rdividedv.m 4414 2014-06-04 06:22:28Z willkomm $
