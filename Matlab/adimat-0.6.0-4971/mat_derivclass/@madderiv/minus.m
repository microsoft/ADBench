function res= minus(s1, s2)
%MADDERIV/MINUS Subtraktion-operator
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isa(s1, 'madderiv')&& isa(s2, 'madderiv')
   res= s1;
   if isequal(s1.sz, s2.sz)
      res.deriv= s1.deriv- s2.deriv;
   elseif all(s1.sz==1)
      res.deriv= kron(s1.deriv, ones(s2.sz))- s2.deriv;
      res.sz= s2.sz;
   else
      res.deriv= s1.deriv- kron(s2.deriv, ones(s1.sz));
   end
else
   error('Subtraktion of madderiv- and non-madderiv-objects is not supported yet!');
end

