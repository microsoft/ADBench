function res= callwo(func, varargin)
%ADDERIV/CALLWO Call func for all derivatives.
%
% call(@f, a, b, c, ...) expects exactly one arg to be a derivative
% object.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University, TU Darmstadt
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

wo = find(cellfun(@isobject, varargin));
g = varargin{wo};

res= adderiv(g);
dr = res.deriv;
dg = g.deriv;

if res.dims==1 
  for i= 1: res.ndd
    dr{i}= feval(func, varargin{1:wo-1}, dg{i}, varargin{wo+1:end});
  end;
else
  for i= 1: res.ndd(1)
    for j=1: res.ndd(2)
      dr{i,j}= feval(func, varargin{1:wo-1}, dg{i,j}, varargin{wo+1:end});
    end
  end
end

res.deriv = dr;
