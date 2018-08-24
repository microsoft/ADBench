% function adj = a_interp1_3(adj, xs, ys, xis, varargin)
%   compute adjoint of xis in interp1(xs, ys, xis, ...)
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_interp1_3(adj, xs, ys, xis, varargin)
  partial = partial_interp1_3(xs, ys, xis, varargin{:});
  adj = (adj(:).' * partial).';
  adj = reshape(adj, size(xis));
% $Id: a_interp1_3.m 3508 2013-01-31 00:18:36Z willkomm $
