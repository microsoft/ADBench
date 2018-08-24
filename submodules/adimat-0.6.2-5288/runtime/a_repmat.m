%
% function adj = a_repmat(adj, varargin)
%   compute adjoint of repmat(val, varargin{:})
%
% see also a_zeros, a_mean
%
% This file is part of the ADiMat runtime environment
%
function r = a_repmat(adj, val, varargin)
  if nargin < 4
    dims = varargin{1};
  else
    dims = [ varargin{:} ];
  end
  if isstruct(val) 
    % FIXME: this only works when first arg to repmat was a scalar struct
    r = adj(1);
    for i=2:numel(adj)
      r = adimat_sumstruct(r, adj(i));
    end
  elseif ismatrix(adj) && length(dims) < 3
    % this only works with repmat along the first two dimensions
    r = repmat(eye(size(val, 1)), 1, dims(1)) ...
        * adj ...
        * repmat(eye(size(val, 2)), dims(2), 1);
  else
    % handle more dims
    szv = size(val);
    sz = size(adj);
    szv = [szv ones(1, length(sz) - length(szv))];
    r = adj;
    for k=1:length(dims)
      r = repmat(eye(size(val, k)), 1, dims(k)) * r(:,:);
      r = reshape(r, [szv(k) sz(k+1:end) szv(1:k-1)]);
      r = shiftdim(r, 1);
    end
  end

% $Id: a_repmat.m 4864 2015-02-07 16:59:51Z willkomm $
