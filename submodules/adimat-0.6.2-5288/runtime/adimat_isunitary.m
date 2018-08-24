function q = adimat_isunitary(A, tol)
  if nargin < 2
    tol = eps .* 100;
  end
  q = norm(A' * A - eye(size(A,1)), 1) ./ norm(A, 1) < tol;
