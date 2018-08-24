% function [g_l, l]= g_eig(g_A, A)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [g_l, l]= g_eig(g_A, A)
  [V D] = eig(A);
  l = diag(D);
  g_l = call(@diag, V \ (g_A * V));
% $Id: g_eig.m 4998 2015-05-18 16:21:55Z willkomm $
