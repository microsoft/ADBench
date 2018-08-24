% function [U T] = adimat_qr_shifts(A, tol)
%
% Compute the Schur form U' A U = T of a matrix A using the QR
% algorithm with simple shifts as described in the lecture notes of
% University Göttingen:
%
% http://lp.uni-goettingen.de/get/text/2139
%
% This is not the state of the art but it seems to work good
% enough. Desirable would be the double shift method so the "real
% schur form" of real matrices with complex eigenvalues can be
% computed in real arthmetic.
%
% See also adimat_hessenberg_householder, adimat_qr_givens
% 
function [U T] = adimat_qr_shifts(A, tol, maxIter)
  if nargin < 2
    tol = 1e-30;
  end
  if nargin < 3
    maxIter = 1e3;
  end
  tolchecks = 1e-12;
  n = size(A,1);
%  [Q H] = adimat_hessenberg_householder(A);
  H = A;
  Q = eye(n);
%  assert(norm(Q' * A * Q - H) ./ norm(A) < tolchecks)
  for i=1:n-1
    j = n - i + 1;
    I = speye(j);
    Ui = eye(j);
    Hi = H(1:j, 1:j);
    iter = 0;
    while iter < maxIter && abs(Hi(j,j-1)) > tol.*norm([Hi(j,j) Hi(j-1,j-1)])
      % determine the shift kappai
      l = adimat_eig2x2(Hi(j-1:j, j-1:j));
%      fprintf(1, 'At i=%d, iter=%d, l=%s\n', i, iter, mat2str(l));
      d = l - Hi(j,j);
      [dummy, mini] = min(d);
      kappai = l(mini);
      % QR decomposition of shifted Hi
      kI = kappai .* I;
      [Qi Ri] = adimat_qr_givens(Hi - kI);
      % New iterate Hi and updated transformation Ui
      Ui = Ui * Qi;
      Hi = Ri * Qi + kI;
%      fprintf(1, 'At i=%d, iter=%d, norm(Hi)=%s\n', i, iter, mat2str(norm(Hi)));
%      assert(norm(Ui' * H(1:j, 1:j) * Ui - Hi) ./ norm(H(1:j, 1:j)) < tolchecks)
      iter = iter + 1;
    end
%    fprintf(1, 'At i=%d, took %d iterations\n', i, iter);
    if iter >= maxIter
      error('too many iterations in QR algorithm');
    end
    U = eye(n);
    U(1:j, 1:j) = Ui;
%    assert(isunitary(U))
    Q = Q * U;
%    assert(isunitary(Q))
    H(1:j, 1:j) = Hi;
    if n > 1
      % Also consider the effects a similarity transform with U
      % would have had on the whole matrix H:
      %             [ Hi      X1 ]
      %   H =  U' * [            ] * U
      %             [ X2      Hr ]
      %   (1)  X1 -> Ui' * X1
      %   (2)  X2 -> X2 * Ui
      % (1)
      H(1:j, j+1:n) = Ui' * H(1:j, j+1:n);
      % (2) is not necessary since H is upper Hessenberg!
      % H(j+1:n, 1:j) = H(j+1:n, 1:j) * Ui;
    end
%    assert(norm(Q' * A * Q - H) ./ norm(A) < tolchecks)
  end
  U = Q;
  T = H;
end
