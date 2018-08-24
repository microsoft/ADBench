% function g_z = g_cross2(g_a, a, g_b, b)
%
% Compute derivative of z = cross(a, b).
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (c) 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright (c) 2016 Johannes Willkomm
function g_z = g_cross2(g_a, a, g_b, b)
  g_z = cross(g_a, b) + cross(a, g_b);
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
% $Id: g_cross2.m 5086 2016-05-18 10:21:26Z willkomm $
