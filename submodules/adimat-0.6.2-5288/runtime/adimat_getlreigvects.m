% function [L R] = adimat_getlreigvects(A, lambda)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [L R] = adimat_getlreigvects(A, lambda)
  neigs = 1;
  tol = 1e-13;
  [R Ds] = eigs(A, neigs, lambda);
  [closest, i] = min(diag(Ds) - lambda);
%  abs(Ds(i) - lambda)
  R = R(:,i);
  assert(abs(Ds(i) - lambda) < tol)
  [L Ds] = eigs(A.', neigs, lambda);
  [closest, i] = min(diag(Ds) - lambda);
%  abs(Ds(i) - lambda)
  L = L(:,i).';
  assert(abs(Ds(i) - lambda) < tol)
%  L = L.';
  l = L*R;
  L = L ./ l;
% $Id: adimat_getlreigvects.m 5004 2015-05-18 21:20:08Z willkomm $
