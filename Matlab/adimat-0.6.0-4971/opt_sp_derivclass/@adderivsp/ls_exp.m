function g_res= ls_exp(g_s1, s1, g_s2, s2, res)
%ADDERIV/LS_EXP Execute the exponentiation rule for two operands elementwise.
%  This operand assumes, that g_s1 and g_s2 are of type adderivsp. There are
%  no checks against misuse.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


g_res= adderivsp(g_s1);

tmp= log(s1);
for i= 1: g_s1.ndd
   g_res.deriv{i}= (g_s2.deriv{i}.* tmp+ s2.* (g_s1.deriv{i}./ s1)).* res;
end

%vim:sts=3:
