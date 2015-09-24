function res= rdivide(s1, s2)
%MADDERIV/RDIVIDE Divide a matrix
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s2, 'madderiv')
   error('Denominator can not be active.');
else 
   res= s1;

   if isscalar(s2)
      res.deriv= s1.deriv./ s2;
   else
      if all(s1.sz==1)
         res.deriv= kron(s1.deriv, ones(size(s2)))./ repmat(s2, s1.ndd);
      else
         res.deriv= s1.deriv./ repmat(s2, s1.ndd);
      end
   end
end

% vim:sts=3:
