% function z = partial_cumtrapz_Y(arg...)
%
% Compute partial derivative of cumtrapz function w.r.t. Y.
% 
% For calling seequence see cumtrapz.
%
% see also cumtrapz
%
% Copyright (C) 2015 Johannes Willkomm
function J = partial_cumtrapz_Y(a, b, c)
  if nargin == 1
    % cumtrapz(Y)
    J = partial_cumtrapz_Y_uni(a);
  elseif nargin == 2
    if isscalar(b)
      % cumtrapz(Y, dim)
      J = partial_cumtrapz_Y_uni(a, b);
    else
      % cumtrapz(X, Y)
      J = partial_cumtrapz_Y_nonuni(a, b);
    end
  else
    % cumtrapz(X, Y, dim)
    J = partial_cumtrapz_Y_nonuni(a, b, c);
  end
end
function J = partial_cumtrapz_Y_uni(Y, dim)
  if nargin < 2
    dim = adimat_first_nonsingleton(Y);
  end
  sz = size(Y);
  bef = prod(sz(1:dim-1));
  aft = prod(sz(dim+1:end));
  nd = sz(dim);
  T = tril(ones(nd),-1) + diag(ones(1, nd).*0.5);
  T(:,1) = 0.5;
  T(1) = 0;
  B = kron(T, eye(bef));
  blks = repmat({B}, [1 aft]);
  J = blkdiag(blks{:});
end
function J = partial_cumtrapz_Y_nonuni(X, Y, dim)
  if nargin < 3
    dim = adimat_first_nonsingleton(Y);
  end
  sz = size(Y);
  bef = prod(sz(1:dim-1));
  aft = prod(sz(dim+1:end));
  nd = sz(dim);
  D2 = diff(X(:)) .* 0.5;
  D = [0; D2] + [D2; 0];
  T = tril(kron(ones(nd, 1), D.'), -1) + diag([0; D2]);
  B = kron(T, eye(bef));
  blks = repmat({B}, [1 aft]);
  J = blkdiag(blks{:});
end
% $Id: partial_cumtrapz_Y.m 4960 2015-03-03 09:21:12Z willkomm $
