% function a_A = a_eig_10_11(a_V, x)
%
% Compute adjoint of A in [V D] = eig(A), given adjoint of V.
%
% see also a_eig_01_11, a_eig_11_11, a_eig_1_11
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function a_A = a_eig_10_11(a_V, A)
  [V D] = eig(A);
  Vi = inv(V);
  F = d_eig_F(diag(D));
  a_A = Vi .' * (F .* (V .' * a_V)) * V .';
  
% $Id: a_eig_10_11.m 3308 2012-06-13 16:29:02Z willkomm $
