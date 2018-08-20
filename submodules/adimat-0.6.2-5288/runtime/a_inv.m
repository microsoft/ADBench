% function adj = a_inv(adj, val)
%   compute adjoint of inv(val)
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function adj = a_inv(adj, val)
  Ait = inv(val) .';
  adj = -Ait * adj * Ait;

% $Id: a_inv.m 3114 2011-11-08 18:19:01Z willkomm $
