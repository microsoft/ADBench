% function a_A = a_eig11(a_V, a_D, A)
%
% Compute adjoint of A in [V D] = eig(A), given adjoints of V and D.
%
% see also a_eig_01_11, a_eig_10_11, a_eig_1_11
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function a_A = a_eig11(a_V, a_D, A)
  [V D] = eig(A);
  F = d_eig_F(diag(D));
  a_D = call(@diag, call(@diag, a_D));
  a_A = V.' \ ((a_D + F .* (V .' * a_V)) * V.');
  
% $Id: a_eig21.m 4987 2015-05-11 15:27:57Z willkomm $
