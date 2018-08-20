% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = timesdd(obj, right)
  obj = binopFlatdd(obj, right, @times);
end
% $Id: timesdd.m 4392 2014-06-03 07:41:31Z willkomm $
