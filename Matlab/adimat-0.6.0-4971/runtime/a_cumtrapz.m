% function z = a_cumtrapz(adj, ind, a, b, c)
%
% Copyright (C) 2015 Johannes Willkomm
function z = a_cumtrapz(adj, ind, a, b, c)
  if nargin-2 == 1
    % cumtrapz(Y)
    if ind == 1
      J_Y = partial_cumtrapz_Y(a);
      z = adj(:).' * J_Y;
      z = reshape(z, size(a));
    else
      z = ascalaradj();
    end
  elseif nargin-2 == 2
    if isscalar(b)
      % cumtrapz(Y, dim)
      if ind == 1
        J_Y = partial_cumtrapz_Y(a, b);
        z = adj(:).' * J_Y;
        z = reshape(z, size(a));
      else
        z = ascalaradj();
      end
    else
      % cumtrapz(X, Y)
      switch ind
       case 1
        J_X = partial_cumtrapz_X(a, b);
        z = adj(:).' * J_X;
        z = reshape(z, size(a));
       case 2
        J_Y = partial_cumtrapz_Y(a, b);
        z = adj(:).' * J_Y;
        z = reshape(z, size(b));
       otherwise
        z = ascalaradj();
      end
    end
  else
    % cumtrapz(X, Y, dim)
    switch ind
     case 1
      J_X = partial_cumtrapz_X(a, b, c);
      z = adj(:).' * J_X;
      z = reshape(z, size(a));
     case 2
      J_Y = partial_cumtrapz_Y(a, b, c);
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
% $Id: a_cumtrapz.m 4880 2015-02-14 17:16:52Z willkomm $
