% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = fliplr(obj)
  obj = flipdim(obj, 2);
end
% $Id: fliplr.m 4323 2014-05-23 09:17:16Z willkomm $
