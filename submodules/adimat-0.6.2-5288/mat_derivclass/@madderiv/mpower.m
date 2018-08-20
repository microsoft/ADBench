function res= mpower(s1, s2)
%MADDERIV/MPOWER Matrix power
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s2, 'madderiv')
   error('Active exponent?! This is never to occur.');
else
   res= s1;
   
   ss2= size(s2);
   if res.dims==1
      inds= 0: s1.ndd(2);
      if isscalar(s2)
         inds= inds.* s1.sz(2);
      elseif all(s1.sz==1)
         res.sz= ss2;
      else
         error('MADDERIV/MPOWER: One input has to be scalar and the other a square matrix.');
      end
      indr= (0: res.ndd(2)).* res.nz(2);
      deriv= zeros(res.sz.* res.ndd);
      for i= 2: (res.ndd(2)+1)
         deriv(:, (indr(i-1)+1): indr(i))=...
                  s1.deriv(:, (inds(i-1)+1):inds(i))^ s2;
      end
      res.deriv= cond_sparse(deriv);
   else
      inds1= 0: s1.ndd(1);
      inds2= 0: s1.ndd(2);
      if isscalar(s2)
         inds1= inds1.* s1.sz(1);
         inds2= inds2.* s1.sz(2);
      elseif all(s1.sz==1)
         res.sz= ss2;
      else
         error('MADDERIV/MPOWER: One input has to be scalar and the other a square matrix.');
      end
      indr1= (0: res.ndd(1)).* res.nz(1);
      indr2= (0: res.ndd(2)).* res.nz(2);
      deriv= zeros(res.sz.*res.ndd);
      for i= 2: (res.ndd(1)+1)
         for j= 2: (res.ndd(2)+1)
            deriv((indr1(i-1)+1): indr1(i), (indr2(j-1)+1): indr2(j))=...
               s1.deriv((inds1(i-1)+1): inds1(i), (inds2(j-1)+1): inds2(j))...
               ^ s2;
         end
      end
      res.deriv= cond_sparse(deriv);
   end
end

