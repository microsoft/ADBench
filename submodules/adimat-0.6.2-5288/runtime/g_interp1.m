% function g_z = g_interp1(g_xs, xs, g_ys, ys, g_xis, xis, method, extrap)
%
% Compute derivative of z = interp1(xs, ys, xis, method, extrap).
%
% see also partial_interp1_1, partial_interp1_2, partial_interp1_3
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function g_z = g_interp1(g_xs, xs, g_ys, ys, g_xis, xis, method, extrap)
  if nargin < 7
    method = 'linear';
  end
  if nargin < 8
    extrap = nan();
  end

  p1 = partial_interp1_1(xs, ys, xis, method, extrap);
  g_z1 = p1 * g_xs(:);

  g_z2 = call(@(t) interp1(xs, t, xis, method, extrap), g_ys);

  p3 = partial_interp1_3(xs, ys, xis, method, extrap);
  g_z3 = p3 * g_xis(:);
  
  g_z = g_z1(:) + g_z2(:) + g_z3(:);
  
  if isvector(ys)
    g_z = reshape(g_z, size(xis));
  else
    szys = size(ys);
    resdim = [numel(xis), szys(2:end)];
    g_z = reshape(g_z, resdim);
  end
 
% $Id: g_interp1.m 3657 2013-05-22 16:39:59Z willkomm $
% Local Variables:
% coding: utf-8
% End:
