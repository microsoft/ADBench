function g_res= ls_exp(g_s1, s1, g_s2, s2, res)
% LS_EXP Execute the exponentiation rule for two operands elementwise.
% This operand assumes, that g_s1 and g_s2 are derivative variables. There are
% no checks against misuse.
%
% Copyright 2013 Johannes Willkomm
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


tmp= log(s1);
g_res = (g_s2 .* tmp + s2 .* g_s1 ./ s1) .* res;
   
