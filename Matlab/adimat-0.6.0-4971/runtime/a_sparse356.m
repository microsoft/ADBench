% function adj = a_sparse(adj, val)
%
% see also a_zeros, a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_sparse356(adj, is, js, vals, m, n, nzmax)
  if nargin < 5
    m = max(is);
  end
  if nargin < 6
    n = max(js);
  end
  inds = sub2ind([m n], is, js);
  adj = reshape(adj(inds), size(vals));
% $Id: a_sparse356.m 3503 2013-01-28 11:44:33Z willkomm $
