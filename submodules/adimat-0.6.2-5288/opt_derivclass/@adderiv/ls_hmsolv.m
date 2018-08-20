function h_res= ls_msolv(h_s1, g_s1, s1, h_s2, g_s2, g_res, res)
%ADDERIV/LS_MSOLV Compute the derivative of the linear equation solver
%	reducing the use of loops.
% !!! ATTENTION !!! The last argument has to be the result of s1\s2 !!!
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

h_res= adderiv(h_s1);

for i= 1: h_s1.ndd(1)
   for j= 1: h_s1.ndd(2) 
      h_res.deriv{i,j}= s1\ (h_s2.deriv{i,j}- h_s1.deriv{i,j}* res- ...
         g_s1.deriv{i}* g_res.deriv{j}- g_s1.deriv{j}* g_res.deriv{i});
   end
end
