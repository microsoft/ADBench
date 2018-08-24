% function z = partial_cumsum(arg...)
%
% Compute partial derivative of cumsum function
% 
% see also cumsum
%
% Copyright (C) 2015 Johannes Willkomm
function J = partial_cumsum(X, dim)
  if nargin < 2
    dim = adimat_first_nonsingleton(X);
  end
  sz = size(X);
  bef = prod(sz(1:dim-1));
  aft = prod(sz(dim+1:end));
  nd = sz(dim);
  O = kron(tril(ones(nd)), speye(bef));
  blks = repmat({O}, [1 aft]);
  J = blkdiag(blks{:});
end
% $Id: partial_cumsum.m 5092 2016-05-18 19:24:45Z willkomm $
