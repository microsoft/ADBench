function res= mrdivide(s1, s2)
%MADDERIV/MRDIVIDE Divide a derivative by a matrix.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s2, 'madderiv')
   error('Denominator is active. This is never to happen!');
else
   if isreal(s1.deriv) && isreal(s2)
      res= transpose(mldivide(s2.', transpose(s1)));
   else
      res= ctranspose(mldivide(s2', ctranspose(s1)));
   end
end

