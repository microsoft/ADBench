function res=numel(g, varargin)
%MADDERIV/numel Return the number of objects returned by the index expression.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if isequal(g.ndd, [0 0]) 
   res= 0;
elseif nargin<2 
   res= 1;
else
   if ischar(varargin{1}) && varargin{1}==':'
      if g.dims==1
         res= g.ndd(2);
      else
         res= g.ndd(1);
      end
   else
      res= length(varargin{1});
   end
   if g.dims== 1
      if nargin>2
         res= res* numel(g.deriv(:,1:g.sz(2)), varargin{2:end});
      end
   else
      if nargin>2
         if (ischar(varargin{2}) && (varargin{2}==':'))
            res= res* g.ndd(2);
         else
            res= res* length(varargin{2});
         end
         if nargin>3
            res= res* numel(g.deriv(1:g.sz(1),1:g.sz(2)), varargin{3:end});
         end
      end
   end
end

% vim:sts=3:
