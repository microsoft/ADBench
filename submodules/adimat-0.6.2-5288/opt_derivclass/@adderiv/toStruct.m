% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm 
%
function res = toStruct(obj)
  res.deriv = obj.deriv;
  res.dims = obj.dims;
  res.ndd = obj.ndd;
  res.left = obj.left;
  res.className = 'adderiv';
end
% $Id: toStruct.m 3862 2013-09-19 10:50:56Z willkomm $
