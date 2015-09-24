% function adj = a_full(adj, val)
%
% see also a_zeros, a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_full(adj, val)
  if issparse(val)
    adj = call(@sparse, adj);
  end
% $Id: a_full.m 3503 2013-01-28 11:44:33Z willkomm $
