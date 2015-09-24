function res= call(func, g, varargin)
%ADDERIV/CALL Call func for all derivatives.
%
% call(@f, g) expects g to be a derivative object, violation of this
% rule results in a crash.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

res= adderivsp(g);

if res.dims==1 
   if nargin>2 
      for i= 1: res.ndd
         res.deriv{i}= cond_sparse(feval(func, g.deriv{i}, varargin{:}));
      end;
   else
      for i= 1: res.ndd
         res.deriv{i}= cond_sparse(feval(func, g.deriv{i}));
      end;
   end
else
   if nargin>2
      for i= 1: res.ndd(1)
         for j=1: res.ndd(2)
            res.deriv{i,j}= cond_sparse(feval(func, g.deriv{i,j}, varargin{:}));
         end
      end
   else
      for i= 1: res.ndd(1)
         for j=1: res.ndd(2)
            res.deriv{i,j}= cond_sparse(feval(func, g.deriv{i,j}));
         end
      end
   end
end

