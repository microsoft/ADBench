% function g_z = g_cross3(g_a, a, g_b, b, dim)
%
% Compute derivative of z = cross(a, b, dim).
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function g_z = g_cross3(g_a, a, g_b, b, dim)
  sza = size(a); % == size(b)
  szr = sza;
  szr(dim) = 1;
  g_z = g_zeros(szr);
  inds1 = cell(1, length(sza));
  for i=1:length(sza)
    inds1{i} = ':';
  end
  inds2 = inds1;
  inds3 = inds1;
  inds1{dim} = 1;
  inds2{dim} = 2;
  inds3{dim} = 3;
  g_z(inds1{:}) = g_a(inds2{:}) .* b(inds3{:}) + a(inds2{:}) .* g_b(inds3{:}) - (g_a(inds3{:}) .* b(inds2{:}) + a(inds3{:}) .* g_b(inds2{:}));
  g_z(inds2{:}) = g_a(inds3{:}) .* b(inds1{:}) + a(inds3{:}) .* g_b(inds1{:}) - (g_a(inds1{:}) .* b(inds3{:}) + a(inds1{:}) .* g_b(inds3{:}));
  g_z(inds3{:}) = g_a(inds1{:}) .* b(inds2{:}) + a(inds1{:}) .* g_b(inds2{:}) - (g_a(inds2{:}) .* b(inds1{:}) + a(inds2{:}) .* g_b(inds1{:}));
% $Id: g_cross3.m 3883 2013-09-26 10:59:15Z willkomm $
