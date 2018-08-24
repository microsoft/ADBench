% function adj = a_sum(adj, val, dimind?)
%   compute adjoint of sum(val, dimind?), where ajd is the adjoint of
%   val
%
% see also a_zeros, a_mean
%
% This file is part of the ADiMat runtime environment
%
function adj = a_sum(adj, val, dimind)
  if nargin < 3
    dimind = adimat_first_nonsingleton(val);
  end
  n = size(val, dimind);
  adj = repmat(adj, adimat_repind(ndims(val), dimind, n));

% $Id: a_sum.m 3307 2012-06-12 16:43:39Z willkomm $
