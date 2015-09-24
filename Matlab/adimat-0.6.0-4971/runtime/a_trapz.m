% function z = a_trapz(adj, ind, a, b, c)
%
% Copyright (C) 2015 Johannes Willkomm
function z = a_trapz(adj, ind, a, b, c)
  if nargin-2 == 1
    % trapz(Y)
    if ind == 1
      J_Y = partial_trapz_Y(a);
      z = adj(:).' * J_Y;
      z = reshape(z, size(a));
    else
      z = ascalaradj();
    end
  elseif nargin-2 == 2
    if isscalar(b)
      % trapz(Y, dim)
      if ind == 1
        J_Y = partial_trapz_Y(a, b);
        z = adj(:).' * J_Y;
        z = reshape(z, size(a));
      else
        z = ascalaradj();
      end
    else
      % trapz(X, Y)
      switch ind
       case 1
        J_X = partial_trapz_X(a, b);
        z = adj(:).' * J_X;
        z = reshape(z, size(a));
       case 2
        J_Y = partial_trapz_Y(a, b);
        z = adj(:).' * J_Y;
        z = reshape(z, size(b));
       otherwise
        z = ascalaradj();
      end
    end
  else
    % trapz(X, Y, dim)
    switch ind
     case 1
      J_X = partial_trapz_X(a, b, c);
      z = adj(:).' * J_X;
      z = reshape(z, size(a));
     case 2
      J_Y = partial_trapz_Y(a, b, c);
      z = adj(:).' * J_Y;
      z = reshape(z, size(b));
     otherwise
      z = ascalaradj();
    end
  end
end
function z = ascalaradj(varargin)
  z = a_zeros(0);
end
% $Id: a_trapz.m 4880 2015-02-14 17:16:52Z willkomm $
