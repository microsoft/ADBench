function res= calln(func, varargin)
%ADDERIV/CALLN Call func with all arguments are gradients.
%
% calln(@f, g_v1, g_v2,..., g_vn) expects all g_vi to be gradient
% objects, violation of this rule results in a crash.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


res= adderivsp(varargin{1});

if nargin>2
   parn= nargin-1;
   temp= cell(parn, 1);
   if res.dims==1
      for i= 1: res.ndd
         for c= 1: parn 
            temp{c}= varargin{c}.deriv{i};
         end
         res.deriv{i}= cond_sparse(feval(func, temp{:}));
      end;
   else
      for i= 1: res.ndd(1)
         for j= 1: res.ndd(2)
            for c= 1: parn 
               temp{c}= varargin{c}.deriv{i,j};
            end
            res.deriv{i}= cond_sparse(feval(func, temp{:}));
         end
      end
   end;
else
   if res.dims==1 
      for i= 1: res.ndd
         res.deriv{i}= cond_sparse(feval(func, varargin{1}.deriv{i}));
      end;
   else
      for i= 1: res.ndd(1)
         for j=1: res.ndd(2)
            res.deriv{i,j}= cond_sparse(feval(func, varargin{1}.deriv{i,j}));
         end;
      end
   end
end;

