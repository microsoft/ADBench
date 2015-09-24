function g_res= ls_msolv(g_s1, s1, g_s2, res)
%MADDERIV/LS_MSOLV Compute the derivative of the linear equation solver
%	reducing the use of loops.
% !!! ATTENTION !!! The last argument has to be the result of s1\s2 !!!
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

g_res= g_s2;

if isscalar(res)
   ssum_size= g_s1.sz;
   ssum= g_s1.deriv* res;
elseif all(g_s1.sz==1)
   ssum_size= size(res);
   h= repmat(g_s1.deriv(:), 1, prod(ssum_size))';
   ssum= reshape(h, ssum_size.* g_s1.ndd).* repmat(res, 1, g_s1.ndd(2));
else
   ssum_size= [g_s1.sz(1) size(res,2)];
   ssum= g_s1.deriv* kron(eye(g_s1.ndd(2)), res);
end

if ~all(g_s1.sz==1)
   g_res.sz(1)= g_s1.sz(2);
end

if all(g_s2.sz==1)
   g_res.deriv= s1\ (reshape(repmat(g_s2.deriv(:), 1, prod(ssum_size))', ...
            ssum_size.* g_s2.ndd) - ssum);
else
   g_res.deriv= s1\ (g_s2.deriv- ssum);
end
      

