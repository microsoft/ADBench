% function g_z = g_cross3(g_a, a, g_b, b, dim)
%
% Compute derivative of z = cross(a, b, dim).
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (c) 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
% Copyright (c) 2016 Johannes Willkomm
function g_z = g_cross3(g_a, a, g_b, b, dim)
  g_z = cross(g_a, b, dim) + cross(a, g_b, dim);
% $Id: g_cross3.m 5086 2016-05-18 10:21:26Z willkomm $
