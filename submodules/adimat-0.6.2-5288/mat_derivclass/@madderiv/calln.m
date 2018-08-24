function res= calln(func, varargin)
%MADDERIV/CALLN Call func with all arguments are gradients.
%
% calln(@f, g_v1, g_v2,..., g_vn) expects all g_vi to be derivative
% objects, violation of this rule results in a crash.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

res= varargin{1};

% Ensure, that func is a function handle and not a string.
if ~ isa(func, 'function_handle')
   func= str2fun(func);
end

ndd= varargin{1}.ndd;

if nargin>2
   parn= nargin-1;
   temp= cell(parn, 1);
   indi= zeros(parn, ndd(1)+2);
   indj= zeros(parn, ndd(2)+2);
   % Compute the arguments for direct. der. (1,1) explicitly,
   for c= 1: parn
      indi(c,:)= varargin{c}.sz(1)* (0: ndd(1)+1)+ 1;
      indj(c,:)= varargin{c}.sz(2)* (0: ndd(2)+1)+ 1;
      temp{c}= varargin{c}.deriv(indi(c,1): indi(c,2)-1, ...
            indj(c,1): indj(c,2)-1);
   end
   tempr= func(temp{:});
   % to learn how much memory is needed in for the result.
   res.sz= size(tempr);
   deriv= zeros(res.sz.* res.ndd);
   resi= (0: res.ndd(1)+ 1).* res.sz(1)+ 1;
   resj= (0: res.ndd(2)+ 1).* res.sz(2)+ 1;
   for i= 2: ndd(1)+ 1
      for j= 2: ndd(2)+ 1
         if (i==2) && (j==2)
            deriv(resi(1): resi(2)-1, resj(1): resj(2)-1)= tempr;
         else
            for c= 1: parn
               temp{c}= varargin{c}.deriv(indi(c,i- 1): indi(c,i)-1, ...
                  indj(c,j- 1): indj(c,j)-1);
            end
            deriv(resi(i-1): resi(i)-1, resj(j-1): resj(j)-1)= func(temp{:});
         end
      end
   end

   res.deriv= cond_sparse(deriv);
else
   g= varargin{1};
   % Compute the arguments for direct. der. (1,1) explicitly,
   indi= (0: ndd(1)+1).* g.sz(1)+ 1;
   indj= (0: ndd(2)+1).* g.sz(2)+ 1;
   tempr= func(g.deriv(indi(1): indi(2)-1, indj(1): indj(2)-1));
   % to learn how much memory is needed in for the result.
   res.sz= size(tempr);
   deriv= zeros(res.sz.* res.ndd);
   resi= (0: res.ndd(1)+ 1).* res.sz(1)+ 1;
   resj= (0: res.ndd(2)+ 1).* res.sz(2)+ 1;
   for i= 2: ndd(1)+ 1
      for j= 2: ndd(2)+ 1
         if (i==2) && (j==2)
            deriv(resi(1): resi(2)-1, resj(1): resj(2)-1)= tempr;
         else
            deriv(resi(i-1): resi(i)-1, resj(j-1): resj(j)-1)= ...
                  func(g.deriv(indi(i-1): indi(i)-1, indj(j-1): indj(j)-1));
         end
      end
   end

   res.deriv= cond_sparse(deriv);
end;
