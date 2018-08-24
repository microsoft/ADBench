function res= plus(s1, s2)
%MADDERIV/PLUS Addition-operator
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s1, 'madderiv')&& isa(s2, 'madderiv')
   res= s1;
   if isequal(s1.sz, s2.sz)
      res.deriv= s1.deriv+ s2.deriv;
   elseif all(s1.sz==1)
      res.deriv= reshape(repmat(s1.deriv, prod(s2.sz), 1), s2.ndd.* s2.sz)+ ...
            s2.deriv;
      res.sz= s2.sz;
   else
      res.deriv= s1.deriv+ reshape(repmat(s2.deriv, prod(s1.sz),1), ...
            s1.ndd.*s1.sz);
   end
else
   error('Sumation of madderiv- and non-madderiv-objects is not supported yet!');
end

