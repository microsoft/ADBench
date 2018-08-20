function res= ls_mprod(g_s1, s1, g_s2, s2)
%ADDERIV/LS_MPROD Execute the product rule for two operands.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if g_s1.dims==1 & g_s2.dims==1
   res= adderivsp(g_s1);
   for i= 1: res.ndd
      res.deriv{i}= cond_sparse(g_s1.deriv{i}* s2+ s1* g_s2.deriv{i});
   end
elseif g_s1.dims==2 & g_s2.dims==1
   res= adderivsp(g_s1);
   % g_s1 = h_s1, s1= g_s1, g_s2= g_s2, s2= s2
   for i= 1: g_s1.ndd(1)
      for j= 1: g_s1.ndd(2)
         res.deriv{i,j}= cond_sparse(g_s1.deriv{i,j}* s2+ ...
               0.5* (s1.deriv{i}* g_s2.deriv{j}+ s1.deriv{j}* g_s2.deriv{i}));
      end
   end
elseif g_s1.dims==1 & g_s2.dims==2
   res= adderivsp(g_s2);
   % g_s1 = g_s1, s1= s1, g_s2= h_s2, s2= g_s2
   for i= 1: g_s2.ndd(1)
      for j= 1: g_s2.ndd(2)
         res.deriv{i,j}= cond_sparse(s1* g_s2.deriv{i,j}+ ...
               0.5* (g_s1.deriv{i}* s2.deriv{j}+ g_s1.deriv{j}* s2.deriv{i}));
      end
   end
else
   error('Internal error.');
end

