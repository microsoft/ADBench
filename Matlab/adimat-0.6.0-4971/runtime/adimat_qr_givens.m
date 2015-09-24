% function [Q R] = adimat_qr_givens(H)
%
% QR-decomposition of an upper Hessenberg matrix using Givens
% rotations.
%
function [Q A] = adimat_qr_givens(A)
  n = size(A,1);
  Q = eye(n);
  for k=1:n-1
    G = mk_givens_elim(A, k+1, k);
    Q = Q * G';
    A = G * A;
  end
end
% $Id: adimat_qr_givens.m 3794 2013-06-26 07:22:03Z willkomm $

