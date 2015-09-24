% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = plus(obj, right)
  obj = binopFlat(obj, right, @plus);
end
% $Id: plus.m 3862 2013-09-19 10:50:56Z willkomm $
