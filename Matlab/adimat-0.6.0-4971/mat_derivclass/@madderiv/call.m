function res= call(func, g, varargin)
%MADDERIV/CALL Call func with one derivative and optional parameters.
%
% call(@f, g) expects g to be a derivative object, violation of this
% rule results in a crash.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

res= g;

% Ensure, that func is a function handle and not a string.
if ~ isa(func, 'function_handle')
   func= str2fun(func);
end

if nargin>2
   indi= g.sz(1)* (0: g.ndd(1)+1)+ 1;
   indj= g.sz(2)* (0: g.ndd(2)+1)+ 1;
   tempr= func(g.deriv(indi(1): indi(2)-1, indj(1): indj(2)-1), varargin{:});
   res.sz= size(tempr);
   deriv= zeros(res.sz.* res.ndd);
   resi= (0: res.ndd(1)+ 1).* res.sz(1)+ 1;
   resj= (0: res.ndd(2)+ 1).* res.sz(2)+ 1;
   % We have to compute the dir derivative (1,1) twice. Once to compute
   % the size of all directional derivatives and once in the loop
   for i= 2: g.ndd(1)+ 1
      for j= 2: g.ndd(2)+ 1
         deriv(resi(i-1): resi(i)-1, resj(j-1): resj(j)-1)= ...
               func(g.deriv(indi(i- 1): indi(i)-1, ...
                  indj(j- 1): indj(j)-1), varargin{:});
      end
   end

   res.deriv= cond_sparse(deriv);
else
   indi= g.sz(1)* (0: g.ndd(1)+1)+ 1;
   indj= g.sz(2)* (0: g.ndd(2)+1)+ 1;
   tempr= func(g.deriv(indi(1): indi(2)-1, indj(1): indj(2)-1));
   res.sz= size(tempr);
   deriv= zeros(res.sz.* res.ndd);
   resi= (0: res.ndd(1)+ 1).* res.sz(1)+ 1;
   resj= (0: res.ndd(2)+ 1).* res.sz(2)+ 1;
   % We have to compute the dir derivative (1,1) twice. Once to compute
   % the size of all directional derivatives and once in the loop
   for i= 2: g.ndd(1)+ 1
      for j= 2: g.ndd(2)+ 1
         deriv(resi(i-1): resi(i)-1, resj(j-1): resj(j)-1)= ...
               func(g.deriv(indi(i- 1): indi(i)-1, ...
                  indj(j- 1): indj(j)-1));
      end
   end

   res.deriv= cond_sparse(deriv);
end;

