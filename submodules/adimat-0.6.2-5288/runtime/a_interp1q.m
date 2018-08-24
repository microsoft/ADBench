% function adj = a_interp1q(adj, xs, ys, xis)
%   compute adjoint of ys in interp1q(xs, ys, xis)
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_interp1q(adj, xs, ys, xis)
  partial = partial_interp1q(xs, ys, xis);
  adj = (adj(:).' * partial).';
  adj = reshape(adj, size(ys));

% $Id: a_interp1q.m 3509 2013-01-31 09:07:53Z willkomm $
