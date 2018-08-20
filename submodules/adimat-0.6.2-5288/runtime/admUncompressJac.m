% function [Jac] = admUncompressJac(compressedJac, pattern, coloring, S)
%
%   Uncompress compressedJac according to pattern and coloring.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [Jac] = admUncompressJac(compressedJac, pattern, coloring, seedW)
  if nargin < 4
    seedW = 1;
  end
  
  sz = size(pattern);
  [is js] = find(pattern);
  % assert(length(is) == nnz(compressedJac));
  n = length(is);
  
  vs = compressedJac(sub2ind(size(compressedJac), is, coloring(js).'));
  
  Jac = sparse(is, js, vs, sz(1), sz(2));
  
  if ~isequal(seedW, 1)
    Jac = Jac * seedW;
  end

%  $Id: admUncompressJac.m 5082 2016-05-08 20:20:33Z willkomm $
