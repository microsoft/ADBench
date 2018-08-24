% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2012,2013 Johannes Willkomm 
%
function obj = zero(obj, val)
  obj = obj.init(zeros(size(val)));
end
% $Id: zero.m 3862 2013-09-19 10:50:56Z willkomm $
