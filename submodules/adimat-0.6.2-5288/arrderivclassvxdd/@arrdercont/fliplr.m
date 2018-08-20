% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2014 Johannes Willkomm 
%
function obj = fliplr(obj)
  obj = flipdim(obj, 2);
end
% $Id: fliplr.m 4344 2014-05-24 07:17:54Z willkomm $
