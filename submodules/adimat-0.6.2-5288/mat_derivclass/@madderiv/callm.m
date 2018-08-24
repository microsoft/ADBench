function [varargout]= callm(func, varargin)
%MADDERIV/CALLM Call func with all arguments are deriv. objs. and varargout
%
% [g_o1, g_o2,... g_om]= callm(@f, g_v1, g_v2,..., g_vn) expects all g_vi
% to be derivative objects, violation of this rule results in a crash.
%
% Copyright 2001-2008 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

   % Get the number of results and initialize them, to be deriv-objs.
   resn= nargout;
   [varargout{1:resn}]= deal(madderiv(varargin{1}));

   ndd= varargin{1}.ndd;

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
   % Initialize a cellarray to take the number of outputs expected
   outcell= cell(1, resn);
   % deriv, resi, and resj just needs to be as long as outcell
   deriv= outcell;
   resi= 0: ndd(1)+ 1;
   resj= 0: ndd(2)+ 1;
   [outcell{:}]= func(temp{:});
   sz= zeros(resn, 2); % Just support 2D objects
   % to learn how much memory is needed for the results.
   for c= 1: resn
      if ndims(outcell{c})>2
         error('The madderiv-class supports only 2D objects for directional derivatives. Current number of dimension is: %d.', ndims(outcell{c}));
      end
      sz(c,:)= size(outcell{c});
      varargout{c}.sz= sz(c,:);
      deriv{c}= zeros(sz(c,:).* ndd);
   end
   resi= sz(:,1)* resi+ 1;
   resj= sz(:,2)* resj+ 1;

   for i= 2: ndd(1)+ 1
      for j= 2: ndd(2)+ 1
         if (i==2) && (j==2)
            for c= 1: resn
               deriv{c}(resi(c,1): resi(c,2)-1, resj(c,1): resj(c,2)-1)= outcell{c};
            end
         else
            for c= 1: parn
               temp{c}= varargin{c}.deriv(indi(c,i- 1): indi(c,i)-1, ...
                  indj(c,j- 1): indj(c,j)-1);
            end
            [outcell{:}]= func(temp{:});
            for c= 1: resn
               deriv{c}(resi(c,i-1): resi(c,i)-1, resj(c,j-1): resj(c,j)-1)= outcell{c};
            end
         end
      end
   end

   for c= 1: resn
      varargout{c}.deriv= cond_sparse(deriv{c});
   end
