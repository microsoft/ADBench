% function g_z = g_cross2(g_a, a, g_b, b)
%
% Compute derivative of z = cross(a, b).
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function g_z = g_cross2(g_a, a, g_b, b)
  g_z = [ g_a(2) .* b(3) + a(2) .* g_b(3) - (g_a(3) .* b(2) + a(3) .* g_b(2))
          g_a(3) .* b(1) + a(3) .* g_b(1) - (g_a(1) .* b(3) + a(1) .* g_b(3))
          g_a(1) .* b(2) + a(1) .* g_b(2) - (g_a(2) .* b(1) + a(2) .* g_b(1))];
  % g_z is a column vector now
  if isrow(a) || isrow(b)
    g_z = g_z .';
    if ~all(size(a) == size(b))
      warning('adimat:runtime:g_cross2', ['cross: The vectors a and b have ' ...
                          'different shape. In this case Matlab ' ...
                          'and Octave return results of different shape. ' ...
                          'ADiMat follows Matlab.'])
    end
  end
% $Id: g_cross2.m 3547 2013-04-04 11:45:26Z willkomm $
