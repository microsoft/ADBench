% function [g_V, V, g_D, D]= g_eig2(g_A, A)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [g_V, V, g_D, D] = g_eig2(g_A, A)
  [V D] = eig(A);
  TMP1 = V \ (g_A * V);
  TMP2 = d_eig_F(diag(D));
  g_D = call(@diag, call(@diag, TMP1));
  g_V = V * (TMP2 .* TMP1);
% $Id: g_eig2.m 4998 2015-05-18 16:21:55Z willkomm $
