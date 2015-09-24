function res= power(s1, s2)
%MADDERIV/POWER Elementwise power
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s2, 'madderiv')
   error('Exponent can not be active.'); 
else 
   res= s1;

   ss2= size(s2);
   if iscalar(s2)
      % Shortcut !!!
      res.deriv= s1.deriv.^ s2;
   else
      if all(s1.sz==1)
         res.sz= size(s2);
         res.deriv= kron(s1.deriv, ones(res.sz)).^ repmat(s2, res.ndd);
      else
         res.deriv= s1.deriv.^ repmat(s2, res.ndd);
      end 
   end
end

