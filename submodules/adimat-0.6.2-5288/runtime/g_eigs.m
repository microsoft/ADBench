% function [g_l, l]= g_eigs(g_A, A)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [g_l, l]= g_eigs(g_A, A, varargin)
  [V D U] = adimat_lreigs(A, varargin{:});

  l = diag(D);
  k = size(U, 2);

  g_l = g_zeros(size(l));
  for i=1:k
    lambda = l(i);
    uk = U(:,i);
    vk = V(i,:);
    dd = vk * (g_A * uk);
    g_l(i,1) = dd;
  end
% $Id: g_eigs.m 5035 2015-05-20 20:25:20Z willkomm $
