% function [d_z z] = adimat_d_trapz(d_a, a, d_b, b, c)
%
% Copyright (C) 2015 Johannes Willkomm
function [d_z z] = adimat_d_trapz(d_a, a, d_b, b, c)
  if nargin == 2
    % trapz(Y)
    z = trapz(a);
    J_Y = partial_trapz_Y(a);
    d_z = admMatMultV1MTb(J_Y, d_a(:,:));
  elseif nargin == 4
    z = trapz(a, b);
    J_Y = partial_trapz_Y(a, b);
    if isscalar(b)
      % trapz(Y, dim)
      d_z = admMatMultV1MTb(J_Y, d_a(:,:));
    else
      % trapz(X, Y)
      J_X = partial_trapz_X(a, b);
      d_z = admMatMultV1MTb(J_X, d_a(:,:)) + admMatMultV1MTb(J_Y, d_b(:,:));
    end
  else
    % trapz(X, Y, dim)
    z = trapz(a, b, c);
    J_X = partial_trapz_X(a, b, c);
    J_Y = partial_trapz_Y(a, b, c);
    d_z = admMatMultV1MTb(J_X, d_a(:,:)) + admMatMultV1MTb(J_Y, d_b(:,:));
  end
  d_z = reshape(d_z, [size(d_a,1) size(z)]); 
end
% $Id: adimat_d_trapz.m 4880 2015-02-14 17:16:52Z willkomm $
