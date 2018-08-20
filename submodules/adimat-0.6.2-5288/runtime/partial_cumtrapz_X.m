% function z = partial_cumtrapz_X(arg...)
%
% Compute partial derivative of cumtrapz function w.r.t. X.
% 
% For calling seequence see cumtrapz.
%
% see also cumtrapz
%
% Copyright (C) 2015 Johannes Willkomm
function J = partial_cumtrapz_X(a, b, c)
  if nargin == 1
    % cumtrapz(Y)
    J = [];
  elseif nargin == 2
    if isscalar(b)
      % cumtrapz(Y, dim)
      J = [];
    else
      % cumtrapz(X, Y)
      J = partial_cumtrapz_X_nonuni(a, b);
    end
  else
    % cumtrapz(X, Y, dim)
    J = partial_cumtrapz_X_nonuni(a, b, c);
  end
end
function J = partial_cumtrapz_X_nonuni(X, Y, dim)
  if nargin < 3
    dim = adimat_first_nonsingleton(Y);
  end
  sy = size(Y);
  bef = prod(sy(1:dim-1));
  aft = prod(sy(dim+1:end));
  nd = sy(dim);
  
  inds = repmat({':'}, [length(sy), 1]);
  inds{dim} = 1:nd-1;
  Y1 = Y(inds{:});
  inds{dim} = 2:nd;
  Y2 = Y(inds{:});

  D = 0.5 .* (Y1 + Y2);
  
  sy1 = sy;
  sy1(dim) = 1;
  J = cat(dim, zeros(sy1), D) - cat(dim, D, zeros(sy1));

  D = reshape(D, [bef nd-1 aft]);
  
  J = reshape(J, [bef nd aft]);
  
  blks = cell(1, aft);
  for j=1:aft
    lines = cell(1, bef);
    for k=1:bef
      Jl = J(k,:,j);
      Jl = tril(kron(ones(nd, 1), Jl),-1) + diag([0 D(k,:,j)]);
      lines{k} = Jl;
    end
    blks{j} = reshape(permute(cat(3, lines{:}), [3 1 2]), [bef*nd nd]);
  end

  J = cat(1, blks{:});
  
end
% $Id: partial_cumtrapz_X.m 4879 2015-02-14 17:04:52Z willkomm $
