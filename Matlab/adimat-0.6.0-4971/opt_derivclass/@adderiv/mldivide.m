function res= mldivide(s1, s2)
%ADDERIV/MLDIVIDE Solve an equation.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


if isa(s1, 'adderiv')
   % If the first argument is active, something wicked has happened.
   error('Never used!!! Bug found.');
else
   res= adderiv(s2);

   if res.dims==1
      tsolv= s1 \ [s2.deriv{:}];
      res.deriv = mat2cell(tsolv, size(tsolv, 1), repmat(size(s2.deriv{1}, 2),[res.ndd,1]));
   else
      for i= 1: res.ndd(1)
         tsolv= s1\ [s2.deriv{i,:}];
         p= size(s2.deriv{i,1}, 2);
         for c=0: res.ndd(2)-1
            res.deriv{i,c+1}= tsolv(:, (c*p+1): ((c+1)*p));
         end
      end
   end
end

