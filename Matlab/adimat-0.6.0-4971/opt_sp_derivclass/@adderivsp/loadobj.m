function res= loadobj(s)
%ADDERIVSP/LOADOBJ Load-operator
%
% Preliminary testing. Be carefull when using!
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isa(s, 'adderivsp')
  res= s;
else
  res= class(s, 'adderivsp');
end

set(res, 'NumberOfDirectionalDerivatives', res.ndd(1));

