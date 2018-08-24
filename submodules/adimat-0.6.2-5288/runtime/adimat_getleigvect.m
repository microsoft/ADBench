% function [L] = adimat_getleigvect(A, lambda, R)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [L] = adimat_getleigvect(A, lambda, R)
  neigs = 1;
  tol = 1e-13;
  [L Ds] = eigs(A.', neigs, lambda);
  [closest, i] = min(diag(Ds) - lambda);
  L = L(:,i).';
  assert(abs(Ds(i) - lambda) < tol)
  L = L ./ (L*R);
% $Id: adimat_getleigvect.m 5005 2015-05-18 21:28:19Z willkomm $
