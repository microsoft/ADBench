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
function a_A = a_eigs_1_31(a_l, A, varargin)
  [V D U] = adimat_lreigs(A, varargin{:});
  [tmp_l] = eigs(A, varargin{:});
  [tmp_l, diag(D), tmp_l - diag(D)]
  %assert(norm(tmp_l - diag(D)) < 1e-12)
  a_D = call(@diag, a_l);
  a_A = V.' * a_D * U.';
% $Id: a_eigs_1_31.m 5061 2015-12-03 07:57:27Z willkomm $
