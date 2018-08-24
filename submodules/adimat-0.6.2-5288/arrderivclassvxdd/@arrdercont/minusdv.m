% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = minusdv(obj, right)
  obj = binopFlatdv(obj, right, @minus);
end
% $Id: minusdv.m 4393 2014-06-03 08:18:50Z willkomm $
