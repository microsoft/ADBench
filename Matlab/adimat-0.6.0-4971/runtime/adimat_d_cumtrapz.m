% function [d_z z] = adimat_d_cumtrapz(d_a, a, d_b, b, c)
%
% Copyright (C) 2015 Johannes Willkomm
function [d_z z] = adimat_d_cumtrapz(d_a, a, d_b, b, c)
  if nargin == 2
    % cumtrapz(Y)
    z = cumtrapz(a);
    J_Y = partial_cumtrapz_Y(a);
    d_z = admMatMultV1MTb(J_Y, d_a(:,:));
  elseif nargin == 4
    z = cumtrapz(a, b);
    J_Y = partial_cumtrapz_Y(a, b);
    if isscalar(b)
      % cumtrapz(Y, dim)
      d_z = admMatMultV1MTb(J_Y, d_a(:,:));
    else
      % cumtrapz(X, Y)
      J_X = partial_cumtrapz_X(a, b);
      d_z = admMatMultV1MTb(J_X, d_a(:,:)) + admMatMultV1MTb(J_Y, d_b(:,:));
    end
  else
    % cumtrapz(X, Y, dim)
    z = cumtrapz(a, b, c);
    J_X = partial_cumtrapz_X(a, b, c);
    J_Y = partial_cumtrapz_Y(a, b, c);
    d_z = admMatMultV1MTb(J_X, d_a(:,:)) + admMatMultV1MTb(J_Y, d_b(:,:));
  end
  d_z = reshape(d_z, [size(d_a,1) size(z)]); 
end
% $Id: adimat_d_cumtrapz.m 4880 2015-02-14 17:16:52Z willkomm $
