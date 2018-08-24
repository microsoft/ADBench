function h_res= ls_hmquot(h_s1, g_s1, s1, h_s2, g_s2, s2, g_res)
%ADDERIV/LS_HMQUOT Execute the matrix quotient rule for Hessians.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

h_res= adderivsp(h_s1);

denom= 1./ (s2^ 2);
g_fac2= 1./ s2* g_s2; % Would be 2/ s2* ..., but this is counter computed
  % with the factor 0.5 in line 17
for i= 1: h_res.ndd(1)
   for j= 1: h_res.ndd(2)
      h_res.deriv{i,j}= cond_sparse((h_s1.deriv{i,j}* s2- s1* h_s2.deriv{i,j})* denom- ...
                      (g_res.deriv{i}* g_fac2.deriv{j}+ ...
                       g_res.deriv{j}* g_fac2.deriv{i})); % Would be ..)* 0.5;
                % but is counter computed with the factor 2 of g_fac2.
   end
end

