function g_res= ls_msolv(g_s1, s1, g_s2, res)
% LS_MSOLV Compute the derivative of the linear equation solver
%	reducing the use of loops.
% !!! ATTENTION !!! The last argument has to be the result of s1\s2 !!!
%
% Copyright 2013 Johannes Willkomm
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  g_res = s1 \ (g_s2 - g_s1 * res);

