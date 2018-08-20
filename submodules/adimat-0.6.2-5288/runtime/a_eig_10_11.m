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
  F = d_eig_F(diag(D));
  useSolve = strcmp(admGetPref('eig_use_solve'), 'yes');
  if useSolve
    a_A = V.' \ ((F .* (V .' * a_V)) * V.');
  else
    a_A = inv(V).' * ((F .* (V .' * a_V)) * V.');
  end  
% $Id: a_eig_10_11.m 5044 2015-06-19 09:39:46Z willkomm $
