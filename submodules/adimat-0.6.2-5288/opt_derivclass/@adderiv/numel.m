function res=numel(g, varargin)
%ADDERIV/numel Return the number of objects returned by the index expression.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

if g.ndd== 0 
  res= 0;
elseif nargin<2 
  res= 1;
else
  if adimat_ismagic(varargin{1})
     res= g.ndd(1);
  else
     res= length(varargin{1});
  end
  if g.dims== 1
     if nargin>2
        res= res* numel(g.deriv{1}, varargin{2:end});
     end
  else
     if nargin>2
        if (ischar(varargin{2}) && (varargin{2}==':'))
           res= res* g.ndd(2);
        else
           res= res* length(varargin{2});
        end
        if nargin>3
           res= res* numel(g.deriv{1,1}, varargin{3:end});
        end
     end
  end
end
 
