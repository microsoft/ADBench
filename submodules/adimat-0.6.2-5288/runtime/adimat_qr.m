function [Q R] = adimat_qr(A)
  [m n] = size(A);
  r = min(m,n);
  Q = eye(m);
  if m <= n && isreal(A), r = r - 1; end
  for k=1:r
    Pk = mk_householder_elim_vec_lapack(A(k:m,k), m);
    Q = Q * Pk;
    A = Pk' * A;
  end
  R = triu(A);
end
% $Id: adimat_qr.m 3962 2013-10-31 09:47:49Z willkomm $
