% function adj = a_cat(adj, v1, v2, ..., vi)
%
% compute adjoint of cat(v1, v2, ..., vi, ..., vn) w.r.t. vi.
%
% see also a_vertcat, a_horzcat, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University, TU Darmstadt
function adj = a_cat(adj, dim, varargin)
  if nargin < 3
    adj = a_zeros(dim);
    return
  end
  sz1 = size(varargin{1});
  indices = repmat({':'}, [1 length(sz1)]);
  offsx = 0;
  for i=1:nargin-3
    offsx = offsx + size(varargin{i}, dim);
  end
  indices{dim} = offsx+1:offsx + size(varargin{end}, dim);
  adj = adj(indices{:});
  adj = reshape(adj, size(varargin{end}));
% $Id: a_cat.m 3672 2013-05-27 10:32:35Z willkomm $
  