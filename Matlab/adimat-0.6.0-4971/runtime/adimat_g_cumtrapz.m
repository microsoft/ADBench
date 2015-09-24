% function [g_z z] = adimat_g_cumtrapz(g_a, a, g_b, b, c)
%
% Copyright (C) 2015 Johannes Willkomm
function [g_z z] = adimat_g_cumtrapz(g_a, a, g_b, b, c)
  if nargin == 2
    % cumtrapz(Y)
    z = cumtrapz(a);
    J_Y = partial_cumtrapz_Y(a);
    g_z = J_Y * g_a(:);
  elseif nargin == 4
    z = cumtrapz(a, b);
    J_Y = partial_cumtrapz_Y(a, b);
    if isscalar(b)
      % cumtrapz(Y, dim)
      g_z = J_Y * g_a(:);
    else
      % cumtrapz(X, Y)
      J_X = partial_cumtrapz_X(a, b);
      g_z = J_X * g_a(:) + J_Y * g_b(:);
    end
  else
    % cumtrapz(X, Y, dim)
    z = cumtrapz(a, b, c);
    J_X = partial_cumtrapz_X(a, b, c);
    J_Y = partial_cumtrapz_Y(a, b, c);
    g_z = J_X * g_a(:) + J_Y * g_b(:);
  end
  g_z = reshape(g_z, size(z)); 
end
% $Id: adimat_g_cumtrapz.m 4880 2015-02-14 17:16:52Z willkomm $
