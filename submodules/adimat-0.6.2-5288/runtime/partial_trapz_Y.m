% function z = partial_trapz_Y(arg...)
%
% Compute partial derivative of trapz function w.r.t. Y
% 
% For calling sequence see trapz.
%
% see also trapz
%
% Copyright (C) 2015 Johannes Willkomm
function J = partial_trapz_Y(a, b, c)
  if nargin == 1
    % trapz(Y)
    J = partial_trapz_Y_uni(a);
  elseif nargin == 2
    if isscalar(b)
      % trapz(Y, dim)
      J = partial_trapz_Y_uni(a, b);
    else
      % trapz(X, Y)
      J = partial_trapz_Y_nonuni(a, b);
    end
  else
    % trapz(X, Y, dim)
    J = partial_trapz_Y_nonuni(a, b, c);
  end
end
function J = partial_trapz_Y_uni(Y, dim)
  if nargin < 2
    dim = adimat_first_nonsingleton(Y);
  end
  sz = size(Y);
  bef = prod(sz(1:dim-1));
  aft = prod(sz(dim+1:end));
  nd = sz(dim);
  if nd < 2
    J = sparse(numel(Y), numel(Y));
    return
  end
  I = speye(bef);
  I2 = 0.5 .* eye(bef);
  Is = [{I2} repmat({I}, [1 nd-2]) {I2}];
  O = cat(2, Is{:});
  blks = repmat({O}, [1 aft]);
  J = blkdiag(blks{:});
end
function J = partial_trapz_Y_nonuni(X, Y, dim)
  if nargin < 3
    dim = adimat_first_nonsingleton(Y);
  end
  sz = size(Y);
  bef = prod(sz(1:dim-1));
  aft = prod(sz(dim+1:end));
  nd = sz(dim);
  if nd < 2
    J = sparse(numel(Y), numel(Y));
    return
  end
  D2 = diff(X(:)) .* 0.5;
  D = [0; D2] + [D2; 0];
  I2 = speye(bef);
  Is = repmat({I2}, [1 nd]);
  for k=1:nd
    Is{k} = Is{k} .* D(k);
  end
  O = cat(2, Is{:});
  blks = repmat({O}, [1 aft]);
  J = blkdiag(blks{:});
end
% $Id: partial_trapz_Y.m 4890 2015-02-16 11:03:23Z willkomm $
