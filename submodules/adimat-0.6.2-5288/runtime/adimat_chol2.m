function U = adimat_chol2(A, low)
% CHOLESKY_FACTOR computes the Cholesky factor of a matrix.
%
% Given a symmetric positive definite matrix A, this function computes the
% upper triangular matrix U such that U'*U = A. Since we are trying to
% mimic a Fortran program, this Matlab implementation works on a scalar
% level, avoiding all vector-like operations.
%
% From an algorithmic point of view, this function produces the output U
% from using the upper triangular part of the input A. The lower tringular
% part of A is never used. That is, using automatic or numerical
% differentiation, the derivatives wrt all entries of the lower triangular
% part will be zero. 

% Author: D. Fabregat Traver, RWTH Aachen University
% Date: 03/08/12
% History: 
% 1) Comment added by Martin Buecker, 03/19/12
% 2) Re-vectorized, second parameter added by Johannes Willkomm, 06/17/12

  if strcmp(lower(low), 'lower')
    U = adimat_chol(A.').';
  else
    U = adimat_chol(A);
  end

end

% $Id: adimat_chol2.m 3739 2013-06-12 16:49:42Z willkomm $
