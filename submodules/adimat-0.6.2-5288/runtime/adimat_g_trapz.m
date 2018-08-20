% function [g_z z] = adimat_g_trapz(g_a, a, g_b, b, c)
%
% Copyright (C) 2015 Johannes Willkomm
function [g_z z] = adimat_g_trapz(g_a, a, g_b, b, c)
  if nargin == 2
    % trapz(Y)
    z = trapz(a);
    J_Y = partial_trapz_Y(a);
    g_z = J_Y * g_a(:);
  elseif nargin == 4
    z = trapz(a, b);
    J_Y = partial_trapz_Y(a, b);
    if isscalar(b)
      % trapz(Y, dim)
      g_z = J_Y * g_a(:);
    else
      % trapz(X, Y)
      J_X = partial_trapz_X(a, b);
      g_z = J_X * g_a(:) + J_Y * g_b(:);
    end
  else
    % trapz(X, Y, dim)
    z = trapz(a, b, c);
    J_X = partial_trapz_X(a, b, c);
    J_Y = partial_trapz_Y(a, b, c);
    g_z = J_X * g_a(:) + J_Y * g_b(:);
  end
  g_z = reshape(g_z, size(z)); 
end
% $Id: adimat_g_trapz.m 4880 2015-02-14 17:16:52Z willkomm $
