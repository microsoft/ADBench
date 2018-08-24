% function adj = a_interp3(adj, xs,ys,zs, v, xis,yis,zis, ...)
%   compute adjoint of v in interp3(adj, xs,ys,zs, v, xis,yis,zis, ...)
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_interp3(adj, xs, ys, zs, v, xis, yis, zis, varargin)
  partial = partial_interp3(xs,ys,zs, v, xis,yis,zis, varargin{:});
  adj = (adj(:).' * partial).';
  adj = reshape(adj, size(ys));
% $Id: a_interp3.m 3509 2013-01-31 09:07:53Z willkomm $
