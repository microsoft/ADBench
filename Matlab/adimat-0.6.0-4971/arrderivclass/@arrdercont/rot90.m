% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function obj = rot90(obj, k)
  if nargin < 2
    k = 1;
  end
  k = mod(k, 4);
  if k < 0, k = k + 4; end
  switch k
   case 0
   case 1
    obj = flipud(obj.');
   case 2
    obj = flipud(fliplr(obj));
   case 3
    obj = flipud(obj).';
  end
end
% $Id: rot90.m 4323 2014-05-23 09:17:16Z willkomm $
