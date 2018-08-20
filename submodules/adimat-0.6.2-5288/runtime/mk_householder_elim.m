% function Pk = mk_householder_elim(A, i, j)
% 
% Compute Pk such that the column under A(i, j), u = A(i:end, j), is
% eliminated, replaced by [norm(u); 0; ...], in Pk'*A*Pk.
%
function Pk = mk_householder_elim(A, i, j)
  n = size(A,1);
  uk = A(i:n,j);

  Pk = mk_householder_elim_vec_lapack(uk, n);
end
% $Id%
