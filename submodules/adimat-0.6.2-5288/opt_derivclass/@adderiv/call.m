function res= call(func, varargin)
%ADDERIV/CALL Call func for all derivatives.
%
% call(@f, g) expects g to be a derivative object, violation of this
% rule results in a crash.
%
% Copyright (c) 2016 Johannes Willkomm, Johannes Willkomm Software Development
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University, TU Darmstadt
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  which = cellfun(@isobject, varargin);
  g = varargin{which};

res= adderiv(g);
dr = res.deriv;
dg = g.deriv;

if res.dims==1 
  for i= 1: res.ndd
    varargin{which} = dg{i};
    dr{i}= feval(func, varargin{:});
  end;
else
  for i= 1: res.ndd(1)
    for j=1: res.ndd(2)
      varargin{which} = dg{i,j};
      dr{i,j}= feval(func, varargin{:});
    end
  end
end

res.deriv = dr;

