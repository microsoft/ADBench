function res= ls_hmprod(h_s1, g_s1, s1, h_s2, g_s2, s2)
%ADDERIV/LS_MPROD Execute the product rule for Hessians.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

res= adderiv(h_s1);

for i= 1: res.ndd
   for j= 1: res.ndd
      res.deriv{i,j}= h_s1.deriv{i,j}* s2+ g_s1.deriv{i}* g_s2.deriv{j}+ ...
                      g_s1.deriv{j}* g_s2.deriv{i}+ s1* h_s2.deriv{i,j};
   end
end

