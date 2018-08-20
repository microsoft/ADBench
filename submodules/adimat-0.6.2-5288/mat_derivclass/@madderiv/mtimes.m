function res= mtimes(s1, s2)
%MADDERIV/MTIMES Multication operator
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isa(s1, 'madderiv')&& isa(s2, 'madderiv')
   if s1.dims==1 && s2.dims==1
      res= madderiv([s1.ndd(2), s2.ndd(2)], [], 'empty');
      if s1.sz(1)==1 && s1.sz(2)==1
         sz= s2.sz;
      elseif s2.sz(1)==1 && s2.sz(2)==2
         sz= s1.sz;
      else
         sz= [s1.sz(1), s2.sz(2)];
      end
      indr1= (0: res.ndd(1)).* sz(1);
      indr2= (0: res.ndd(2)).* sz(2);
      inds1= (0: s1.ndd(2)).* s1.sz(1);
      inds2= (0: s2.ndd(2)).* s2.sz(2);
      deriv=zeros(sz);
      for i= 2: (res.ndd(1)+1)
         for j= 2: (res.ndd(2)+1)
            deriv((indr1(i-1)+1): indr1(i), (indr2(j-1)+1): indr2(j))= ...
                  0.5*(s1.deriv(:, (inds1(i-1)+1): inds1(i))* ...
                       s2.deriv(:, (inds2(j-1)+1): inds2(j))+ ...
                       s1.deriv(:, (inds1(j-1)+1): inds1(j))* ...
                       s2.deriv(:, (inds2(i-1)+1): inds2(i)));
         end
      end
      res.sz= sz;
   else
      error('Multiplication of two derivative objects is defined for one-dimensional objects only.');
   end
elseif isa(s1, 'madderiv')
   res= s1;

   if res.dims==1
      ss2= size(s2);
      if isscalar(s2)
         res.deriv= s1.deriv* s2;
      else
%         inds= (0: s1.ndd(2)).* s1.sz(2);
%         indr= (0: res.ndd(2)).* ss2(2);
         if all(s1.sz==1)
            res.sz= ss2;
            res.deriv= cond_sparse(reshape(repmat(s1.deriv, numel(s2),1 ), ...
                     ss2.* s1.ndd).* repmat(s2, s1.ndd));
         else
            res.sz= [s1.sz(1), ss2(2)];
            res.deriv= cond_sparse(s1.deriv* kron(eye(s1.ndd(2)), s2));
         end
%         deriv=zeros(res.sz.* res.ndd);
%         for c= 2: (res.ndd(2)+1)
%            deriv(:, (indr(c-1)+1): indr(c))= ...
%                              s1.deriv(:, (inds(c-1)+1): inds(c))* s2;
%         end
%         res.deriv= cond_sparse(deriv);
      end
   else
      ss2= size(s2);
      if isscalar(s2)
         deriv= s1.deriv* s2;
      else
         inds1= (0: s1.ndd(1))* s1.sz(1);
         inds2= (0: s1.ndd(2))* s1.sz(2);
         nr1= s1.sz(1)* res.ndd(1);
         nr2= ss2(2)* res.ndd(2);
         indr1= 0: s1.sz(1): nr1;
         indr2= 0: ss2(2): nr2;
         deriv=zeros(nr1, nr2);
         for c1= 2: (res.ndd(1)+1)
            for c2= 2: (res.ndd(2)+1)
               deriv((indr1(c1-1)+1):indr1(c1), (indr2(c2-1)+1):indr2(c2))=...
                           s1.deriv((inds1(c1-1)+1): inds1(c1), ...
                                    (inds2(c2-1)+1): inds2(c2))* s2;
            end
         end
         res.sz=[s1.sz(1), ss2(2)];
      end
      res.deriv= cond_sparse(deriv);
   end
else
   res= s2;

   if res.dims==1
      ss1=size(s1);
      if all(s2.sz==1)
         res.deriv= cond_sparse(repmat(s1, s2.ndd).* ...
               reshape(repmat(s2.deriv, prod(ss1), 1),...
                     ss1.* s2.ndd));
         res.sz= ss1;
      else
   		% Change res.sz, only if x1 is not scalar.
         % If x1 is scalar, then the correct size has already
		   % been inserted by the copyconstructor.
         if ~isscalar(s1)
            res.sz= [ss1(1), s2.sz(2)];
         end
         res.deriv= cond_sparse(s1* s2.deriv);
      end
   else
      ss1=size(s1);
      if isscalar(s1)
         res.deriv= cond_sparse(s1* s2.deriv);
      else
         rs= [size(s1,1), s2.sz(2)];
         indr= 0: ss1: rs(1)* res.ndd(1);
         inds= 0: s2.sz(1): size(s2.deriv, 1);
         deriv= zeros(rs.* res.ndd);
         for c= 2: (res.ndd(1)+1)
            deriv((indr(c-1)+1): indr(c) , :)= ...
                      s1* s2.deriv((inds(c-1)+1): inds(c), :);
         end
         res.deriv= cond_sparse(deriv);
         res.sz= rs;
      end
   end
end

% vim:sts=3:sw=3:

