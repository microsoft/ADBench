function res= times(s1, s2)
%MADDERIV/TIMES Multiplication operator
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
      elseif s2.sz(1)==1 && s2.sz(2)==1
         sz= s1.sz;
      else
         sz= [s1.sz(1), s2.sz(2)];
      end
      indr1= (0: res.ndd(1)).* sz(1);
      indr2= (0: res.ndd(2)).* sz(2);
      inds1= (0: s1.ndd(2)).* s1.sz(1);
      inds2= (0: s2.ndd(2)).* s2.sz(2);
      deriv= zeros(sz);
      for i= 2: (s1.ndd(2)+1)
         deriv((indr1(i-1)+1): indr1(i), :)= ...
            0.5.*( ...
            repmat(s1.deriv(:, (inds1(i-1)+1): inds1(i)),1, res.ndd(2)).* ...
            s2.deriv+ ...
            s1.deriv.* ...
            repmat(s2.deriv(:, (inds2(i-1)+1): inds2(i)),1, res.ndd(1)));
      end
      res.sz=sz;
      res.deriv= cond_sparse(deriv);
   else
      error('Multiplication of two derivative objects is defined for one-dimensional objects only.');
   end
   return
end

if isa(s2, 'madderiv')
   % Ensure that s1 is the madderiv. Implement the code once only.
   tmp= s2;
   s2= s1;
   s1= tmp;
end

res= s1;

if isscalar(s2)
   res.deriv= s1.deriv.* s2;
elseif all(s1.sz==1)
   ss2= size(s2);
   res.deriv= kron(s1.deriv, ones(ss2)).* repmat(s2, s1.ndd);
   res.sz= ss2;
else
   res.deriv= s1.deriv.* repmat(s2, s1.ndd);
end

% vim:sts=3:sw=3:

