% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = minusddes(obj, right)
  obj = binopFlatddes(obj, right, @minus);
end
% $Id: minusddes.m 4393 2014-06-03 08:18:50Z willkomm $
