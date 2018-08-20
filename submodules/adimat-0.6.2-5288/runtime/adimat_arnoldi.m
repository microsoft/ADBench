function [Q H hkkm1] = adimat_arnoldi(A, m, qk)
  n = size(A,1);
  if nargin < 2
    m = n;
  end
  H = zeros(m);
  Q = eye(n, m);
  if nargin < 3
    if isreal(A)
      qk = rand(n,1);
    else
      qk = complex(rand(n,1), rand(n,1));
    end
  end
  nexist = size(qk,2);
  Q(:,1:nexist) = qk;
  qk = qk(:,end);
  qk = qk ./ norm(qk);
  startInd = 1;
  for k=nexist+1:m+1
    qk = A * qk;
    for j=startInd:k-1
      hjkm1 = Q(:,j)' * qk;
      qk = qk - hjkm1 .* Q(:,j);
      H(j,k-1) = hjkm1;
    end
    if isequal(qk, 0)
      hkkm1 = 0;
    else
      hkkm1 = norm(qk);
    end
    if k == m+1
      if m == n
        if hkkm1 > eps .* 1e2
          warning('adimat:arnoldi:inaccurate', 'Large error in Arnoldi iteration k=%d:%g', k, hkkm1);
        end
        if hkkm1 > eps .* 1e4
          warning('adimat:arnoldi:failure', 'Very large error in Arnoldi iteration k=%d:%g', k, hkkm1);
        end
      end
    else
      if hkkm1 < eps
        warning('adimat:arnoldi:breakdown', 'Breakdown in Arnoldi iteration at k=%d', k);
        break
      end
    end
    if hkkm1 == 0 || k == m+1
      break; 
    end
    qk = qk ./ hkkm1;
    H(k,k-1) = hkkm1;
    Q(:,k) = qk;
  end
end
% $Id: adimat_arnoldi.m 3980 2013-12-21 11:03:40Z willkomm $
