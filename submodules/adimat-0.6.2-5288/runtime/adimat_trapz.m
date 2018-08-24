% function z = adimat_trapz(varargin)
%
% ADiMat replacement function for trapz
%
% Copyright (C) 2015 Johannes Willkomm
function z = adimat_trapz(a, b, c)
  if nargin == 1
    % trapz(Y)
    z = adimat_trapz_uni1(a);
  elseif nargin == 2
    if isscalar(b)
      % trapz(Y, dim)
      z = adimat_trapz_uni2(a, b);
    else
      % trapz(X, Y)
      z = adimat_trapz_nonuni2(a, b);
    end
  else
    % trapz(X, Y, dim)
    z = adimat_trapz_nonuni3(a, b, c);
  end
end
function z = adimat_trapz_uni1(Y)
  dim = adimat_first_nonsingleton(Y);
  z = adimat_trapz_uni2(Y, dim);
end
function z = adimat_trapz_uni2(Y, dim)
  if nargin < 2
    dim = adimat_first_nonsingleton(Y);
  end
  len = size(Y, dim);
  if len < 2
    z = zeros(size(Y));
  else
    inds = repmat({':'}, [length(size(Y)), 1]);
    inds{dim} = 2:len-1;
    Y(inds{:}) = Y(inds{:}) .* 2;
    z = 0.5 .* sum(Y, dim);
  end
end
function z = adimat_trapz_nonuni2(X, Y, dim)
  dim = adimat_first_nonsingleton(Y);
  z = adimat_trapz_nonuni3(X, Y, dim);
end
function z = adimat_trapz_nonuni3(X, Y, dim)
  len = size(Y, dim);
  if len < 2
    z = zeros(size(Y));
  else
    ndim = length(size(Y));
    D = diff(X);
    a = 0;
    b = sum(D);
    N = len;
    D = reshape(D, [ones(1,dim-1) len-1 ones(1,ndim-dim)]);
    sy1 = size(Y);
    sy1(dim) = 1;
    D = repmat(D, sy1);
    inds = repmat({':'}, [length(size(Y)), 1]);
    inds{dim} = 1:len-1;
    Y1 = Y(inds{:});
    inds{dim} = 2:len;
    Y2 = Y(inds{:});
    z = 0.5 * (sum(Y1 .* D, dim) + sum(Y2 .* D, dim));
  end
end
% $Id: adimat_trapz.m 4860 2015-02-07 13:49:39Z willkomm $
