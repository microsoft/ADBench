function res= mpower(s1, s2)
%ADDERIV/MPOWER Matrix power
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s2, 'adderiv')
   error('Active exponent?! This is never to occur.');
else
   res= adderiv(s1);

   if res.dims==1
      for i= 1: s1.ndd
         res.deriv{i}= s1.deriv{i}^ s2;
      end
   else
      for i= 1: s1.ndd(1)
         for j= 1: s1.ndd(2)
            res.deriv{i,j}= s1.deriv{i,j}^ s2;
         end
      end
   end
end

