function res= loadobj(s)
%MADDERIV/LOADOBJ Load-operator
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isa(s, 'madderiv')
  res= s;
else
  res= class(s, 'madderiv');
%  error 'Can not load adderivsp object.';
end

set(res, 'NumberOfDirectionalDerivatives', res.ndd);

