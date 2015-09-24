function q = adimat_issymmetric(A, tol)
  if nargin < 2
    tol = eps .* 100;
  end
  q = norm(A' - A, 1) ./ norm(A, 1) < tol;
