function res=end(g, k, n)
% ADDERIV/END(G, K, N) hands the index-expression down to the objects stored
% in the derivative.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
  sz = size(g.deriv{1});
  if k == n
    res = prod(sz(k:end));
  else
    res = sz(k);
  end
end
