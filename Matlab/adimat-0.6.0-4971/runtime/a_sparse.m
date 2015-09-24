% function adj = a_sparse(adj, val)
%
% see also a_zeros, a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_sparse(adj, val)
  adj = call(@full, adj);
% $Id: a_sparse.m 3503 2013-01-28 11:44:33Z willkomm $
