% function [Q H] = adimat_hess(A)
% 
% Compute Q and H such that H = Q' * A * Q and H is upper
% Hessenberg.
%
% This is ADiMat's replacement for the builtin function [Q H] =
% hess(A), to be used for AD.
%
% TODO: This function is for general matrices. There is a special
% algorithm in LAPACK for symmetric/hermitian matrices.
%
function [Q H] = adimat_hess(A)
  n = size(A,1);
  Q = eye(n);
  H = A;
  
  for k=1:n-1
    Pk = mk_householder_elim(H, k+1, k);
    Q = Q * Pk;
    H = Pk' * H * Pk;
  end

  if adimat_issymmetric(H)
    H = tril(triu(real(H), -1), 1);
  else
    H = triu(H) + real(triu(tril(H, -1), -1));
  end

end
% $Id: adimat_hess.m 3865 2013-09-19 15:57:49Z willkomm $
