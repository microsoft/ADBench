function h_res= ls_hmexp(h_s1, g_s1, s1, h_s2, g_s2, s2, g_res, res)
%ADDERIV/LS_MEXP Execute the exponentiation rule for two operands.
%  This operand assumes, that g_s1 and g_s2 are of type adderiv. There are
%  no checks against misuse.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


h_res= adderiv(h_s1);

tmp= log(s1);
g_tmp= g_s1./ s1;
tmp2= 1/ (s1^ 2);
g_tmp4= ls_mprod(g_s2, s2, g_tmp, tmp);
for i= 1: h_s1.ndd(1)
   for j= 1: h_s1.ndd(2) 
      h_res.deriv{i,j}= (h_s2.deriv{i,j}* tmp+ ...
         g_s2.deriv{i}* g_tmp.deriv{j}+ ...
         g_s2.deriv{j}* g_tmp.deriv{i}+ ...
         s2* (h_s1.deriv{i,j}* s1- ...
            0.5* (g_s1.deriv{i}* g_s1.deriv{j}+ ...
                   g_s1.deriv{j}* g_s1.deriv{i}))* tmp2)* res+ ...
         0.5* (g_tmp4.deriv{i}* g_res.deriv{j}+ ...
                g_tmp4.deriv{j}* g_res.deriv{i});
   end
end

% vim:sts=3:
