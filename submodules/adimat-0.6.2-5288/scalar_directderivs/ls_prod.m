function res= ls_prod(g_s1, s1, g_s2, s2)
% LS_PROD Execute the product rule for two operands.
%
% Copyright 2013 Johannes Willkomm
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  res = g_s1 .* s2 + s1 .* g_s2;
