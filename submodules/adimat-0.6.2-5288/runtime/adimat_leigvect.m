% function [L] = adimat_leigvect(A, lambda, R)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [L, l_out] = adimat_leigvect(A, lambda, R)
  neigs = 1;
  tol = 1e-13;
  [L Ds] = eigs(A.', neigs, lambda);
  [closest, i] = min(abs(diag(Ds) - lambda));
  L = L(:,i).';
  l_out = Ds(i,i);
  assert(abs(l_out - lambda) < tol)
  L = L ./ (L*R);
% $Id: adimat_leigvect.m 5035 2015-05-20 20:25:20Z willkomm $
