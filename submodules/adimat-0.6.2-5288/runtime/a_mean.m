% function adj = a_mean(val, adj, dimind?)
%   compute adjoint of mean(val, dimind?)
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function adj = a_mean(adj, val, dimind)
  if nargin < 3
    dimind = adimat_first_nonsingleton(val);
  end
  n = size(val, dimind);
  adj = repmat(adj ./ n, adimat_repind(ndims(val), dimind, n));

% $Id: a_mean.m 3114 2011-11-08 18:19:01Z willkomm $
