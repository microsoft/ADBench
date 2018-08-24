% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = timesddes(obj, right)
  obj = binopFlatddes(obj, right, @times);
end
% $Id: timesddes.m 4393 2014-06-03 08:18:50Z willkomm $
