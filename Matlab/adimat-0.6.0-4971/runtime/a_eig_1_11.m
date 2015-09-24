% function a_A = a_eig_1_11(a_l, A)
%
% Compute adjoint of A in l = eig(A), given adjoint of l.
%
% see also a_eig_10_11, a_eig_01_11, a_eig_11_11
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function a_A = a_eig_1_11(a_l, A)
  [V D] = eig(A);
  Vi = inv(V);
  a_D = call(@diag, a_l);
  a_A = Vi .' * (a_D) * V .';
  
% $Id: a_eig_1_11.m 3308 2012-06-13 16:29:02Z willkomm $
