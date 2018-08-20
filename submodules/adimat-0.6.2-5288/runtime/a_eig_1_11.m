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
  a_D = call(@diag, a_l);
  useSolve = strcmp(admGetPref('eig_use_solve'), 'yes');
  if useSolve
    a_A = V.' \ (a_D * V.');
  else
    a_A = inv(V).' * (a_D * V.');
  end
% $Id: a_eig_1_11.m 5044 2015-06-19 09:39:46Z willkomm $
