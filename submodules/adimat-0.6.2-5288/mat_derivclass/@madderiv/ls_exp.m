function g_res= ls_exp(g_s1, s1, g_s2, s2, res)
%MADDERIV/LS_EXP Execute the exponentiation rule for two operands elementwise.
%  This operand assumes, that g_s1 and g_s2 are of type adderiv. There are
%  no checks against misuse.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


g_res= g_s1;

tmp= log(s1);
if isscalar(s1)
   g_res.sz= g_s2.sz;
   deriv= g_s2.deriv.* tmp+ repmat(s2, g_s1.ndd).* ...
         reshape(repmat(g_s1.deriv./ s1, prod(g_s2.sz), 1), ...
            g_s2.sz.* g_s1.ndd);
   if isscalar(res)
      g_res.deriv= deriv.* res;
   else
      g_res.deriv= deriv.* repmat(res, g_s1.ndd);
   end
elseif isscalar(s2)
   % Size is given by s1!
   deriv= reshape(repmat(g_s2.deriv, prod(g_s1.sz), 1), g_s1.sz.* g_s1.ndd).*...
         repmat(tmp, g_s1.ndd)+ s2.* (g_s1.deriv./ repmat(s1, g_s1.ndd));
   if isscalar(res)
      g_res.deriv= deriv.* res;
   else
      g_res.deriv= deriv.* repmat(res, g_s1.ndd);
   end
else
   g_res.deriv= (g_s2.deriv.* repmat(tmp, g_s1.ndd)+ repmat(s2, g_s1.ndd).* ...
         (g_s1.deriv./ repmat(s1, g_s1.ndd))).* repmat(res, g_s1.ndd);
end

