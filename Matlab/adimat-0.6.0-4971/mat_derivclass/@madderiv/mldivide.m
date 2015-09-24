function res= mldivide(s1, s2)
%MADDERIV/MLDIVIDE Solve an equation.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s1, 'madderiv')
   % If the first argument is active, something wicked has happened.
   error('Never used!!! Bug found.');
else
   res= s2;

   if res.dims==1
      res.deriv= s1\ s2.deriv;
      if ~isscalar(s1)
         res.sz(1)= size(s1, 2);
      end
   else
      ss1= size(s1);
      res.sz(1)= ss1(2);
      indr= 0: ss1(2): ss1(2)*res.ndd(1);
      inds= 0: s2.sz(1): s2.sz(1)* res.ndd(1);
      deriv= zeros(res.sz.*res.ndd);
      for i= 2: (res.ndd(1)+1)
         deriv((indr(i-1)+1): indr(i), :)= s1\ ...
                        s2.deriv((inds(i-1)+1): inds(i), :);
      end
      res.deriv= cond_sparse(deriv);
   end
end

