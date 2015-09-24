function res= ls_prod(g_s1, s1, g_s2, s2)
%MADDERIV/LS_PROD Execute the product rule for two operands.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if g_s1.dims==1 && g_s2.dims==1
   res= g_s1;
   if isscalar(s2)
      if isscalar(s1)
         res.deriv= g_s1.deriv.* s2+ s1.* g_s2.deriv;
      else
         res.deriv= g_s1.deriv.* s2+ ...
                 repmat(s1, g_s2.ndd).* kron(g_s2.deriv, ones(g_s1.sz));
      end
   elseif isscalar(s1)
      res.deriv= kron(g_s1.deriv, ones(g_s2.sz)).* repmat(s2, g_s1.ndd)+...
                 s1.* g_s2.deriv;
      res.sz= g_s2.sz;
   else
      res.deriv=  g_s1.deriv.* repmat(s2, g_s1.ndd)+ ...
                  repmat(s1, g_s2.ndd).* g_s2.deriv;
   end
elseif g_s1.dims==2 && g_s2.dims==1
   res= madderiv(g_s1);
   % g_s1 = h_s1, s1= g_s1, g_s2= g_s2, s2= s2
%   for i= 1: g_s1.ndd(1)
%      for j= 1: g_s1.ndd(2)
%         res.deriv{i,j}= g_s1.deriv{i,j}.* s2+ ...
%               0.5* (s1.deriv{i}.* g_s2.deriv{j}+ s1.deriv{j}.* g_s2.deriv{i});
%      end
%   end
elseif g_s1.dims==1 && g_s2.dims==2
   res= madderiv(g_s2);
%   % g_s1 = g_s1, s1= s1, g_s2= h_s2, s2= g_s2
%   for i= 1: g_s2.ndd(1)
%      for j= 1: g_s2.ndd(2)
%         res.deriv{i,j}= s1.* g_s2.deriv{i,j}+ ...
%               0.5* (g_s1.deriv{i}.* s2.deriv{j}+ g_s1.deriv{j}.* s2.deriv{i});
%      end
%   end
else
   error('Internal error.');
end

