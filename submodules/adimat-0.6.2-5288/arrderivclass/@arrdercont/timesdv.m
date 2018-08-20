% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = timesdv(obj, right)
  obj = binopFlatdv(obj, right, @times);
end
% $Id: timesdv.m 4392 2014-06-03 07:41:31Z willkomm $
