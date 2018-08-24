% function a_A = a_eigs_01_31(a_U, a_D, A, k?, sigma?)
%
% Compute adjoint of A in [V D] = eig(A), given adjoint of D.
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function a_A = a_eigs_01_31(a_D, A, varargin)
  [V D U] = adimat_lreigs(A, varargin{:});
  a_A = V.' * call(@diag, call(@diag, a_D)) * U.';
% $Id: a_eigs_01_31.m 5038 2015-05-21 09:34:38Z willkomm $
