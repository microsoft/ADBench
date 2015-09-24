% function z = partial_trapz_X(arg...)
%
% Compute partial derivative of trapz function w.r.t. X
% 
% For calling sequence see trapz.
%
% see also trapz
%
% Copyright (C) 2015 Johannes Willkomm
function J = partial_trapz_X(a, b, c)
  if nargin == 1
    % trapz(Y)
    J = [];
  elseif nargin == 2
    if isscalar(b)
      % trapz(Y, dim)
      J = [];
    else
      % trapz(X, Y)
      J = partial_trapz_X_nonuni(a, b);
    end
  else
    % trapz(X, Y, dim)
    J = partial_trapz_X_nonuni(a, b, c);
  end
end
function J = partial_trapz_X_nonuni(X, Y, dim)
  if nargin < 3
    dim = adimat_first_nonsingleton(Y);
  end
  sy = size(Y);
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
  J = permute(J, [1:dim-1 dim+1:length(sy) dim]);
  J = reshape(J, [prod(sy1) numel(X)]);
end
% $Id: partial_trapz_X.m 4878 2015-02-14 16:56:49Z willkomm $
