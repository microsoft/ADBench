function g=transpose(g)
%MADDERIV/TRANSPOSE Transpose the derivative
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


sz= [g.sz(2) g.sz(1)];
if g.dims==1
   if issparse(g.deriv)
      g.deriv= sparse(reshape(permute(reshape(full(g.deriv), ...
                 [g.sz g.ndd(2)]),[2,1,3]), sz.* g.ndd));
   else
      g.deriv= reshape(permute(reshape(g.deriv, ...
                 [g.sz g.ndd(2)]),[2,1,3]), sz.* g.ndd);
   end
else
  g.deriv= cond_sparse(reshape(permute(reshape(full(g.deriv), ...
              [g.sz g.ndd]),[2,1,3,4]), sz.* g.ndd));
end
g.sz= sz;

