% function z = adimat_cumtrapz(varargin)
%
% ADiMat replacement function for cumtrapz
%
% Copyright (C) 2015 Johannes Willkomm
function z = adimat_cumtrapz(a, b, c)
  if nargin == 1
    % trapz(Y)
    z = adimat_cumtrapz_uni1(a);
  elseif nargin == 2
    if isscalar(b)
      % trapz(Y, dim)
      z = adimat_cumtrapz_uni2(a, b);
    else
      % trapz(X, Y)
      z = adimat_cumtrapz_nonuni2(a, b);
    end
  else
    % trapz(X, Y, dim)
    z = adimat_cumtrapz_nonuni3(a, b, c);
  end
end
function z = adimat_cumtrapz_uni1(Y)
  dim = adimat_first_nonsingleton(Y);
  z = adimat_cumtrapz_uni2(Y, dim);
end
function z = adimat_cumtrapz_uni2(Y, dim)
  len = size(Y, dim);
  if len < 2
    z = zeros(size(Y));
  else
    inds = repmat({':'}, [length(size(Y)), 1]);
    inds{dim} = 1:len-1;
    Y1 = Y(inds{:});
    inds{dim} = 2:len;
    Y2 = Y(inds{:});
    z = 0.5 .* (cumsum(Y1, dim) + cumsum(Y2, dim));
    sy = size(Y);
    sy(dim) = 1;
    z = cat(dim, zeros(sy), z);
  end
end
function z = adimat_cumtrapz_nonuni2(X, Y, dim)
  dim = adimat_first_nonsingleton(Y);
  z = adimat_cumtrapz_nonuni3(X, Y, dim);
end
function z = adimat_cumtrapz_nonuni3(X, Y, dim)
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
    z = 0.5 * (cumsum(Y1 .* D, dim) + cumsum(Y2 .* D, dim));
    z = cat(dim, zeros(sy1), z);
  end
end
% $Id: adimat_cumtrapz.m 4860 2015-02-07 13:49:39Z willkomm $
