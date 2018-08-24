function g_res= ls_mexp(g_s1, s1, g_s2, s2, res)
%ADDERIV/LS_MEXP Execute the exponentiation rule for two operands.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  g_res = adimat_g_pow(g_s1, s1, g_s2, s2);

