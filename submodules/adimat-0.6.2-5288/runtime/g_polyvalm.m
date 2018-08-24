% function [g_z z] = g_polyvalm(g_p, p, g_x, x)
%
% Compute derivative of z in z = polyval(p, x), matrix polynomial
% p(x), given the derivatives of p and x.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = g_polyvalm(g_p, p, g_x, x)
  deg = length(p);
  szx = size(x);

  Id = ones(szx(1), 1);
  
  g_z = call(@diag, g_p(1) .* Id);
  z = diag(p(1) .* Id);
  for i=2:deg
    g_z = g_x * z + x * g_z + call(@diag, g_p(i) .* Id);
    z = x * z + diag(p(i) .* Id);
  end

% $Id: g_polyvalm.m 3303 2012-06-07 10:48:55Z willkomm $
