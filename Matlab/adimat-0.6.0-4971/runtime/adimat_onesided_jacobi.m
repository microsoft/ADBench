function [z A V nt] = adimat_onesided_jacobi(A, nA1)

  [m n] = size(A);
  nt = n; % matrix is tall, m > n
  
  slimit = max(n./4, 6) .* 10;
  
  if nargout > 2
    V = eye(n, n);
  end
  
  z = zeros(nt,1);

  if nt == 1
    z(1) = A' * A;
  end
  
  tol = eps;
  
  noRotationHere = 0;

  scount = 0;
  rcount = nt .* (nt-1) ./ 2;

  while scount <= slimit && rcount > 0
    rcount = nt .* (nt-1) ./ 2;
    for j=1:nt-1
      for k=j+1:nt
        noRotationHere = 0;

        p = A(:,j)' * A(:,k);
        q = A(:,j)' * A(:,j);
        r = A(:,k)' * A(:,k);
        z(j) = q;
        z(k) = r;
        
        if q < r
          q = q./r - 1;
          p = p./r;
          vt = sqrt(4.*conj(p).*p + q.*q);
          s = sqrt(0.5 .* (1 - q./vt));
          if p < 0
            s = -s;
          end
          c = p./ (vt .* s);
        elseif q.*r <= eps.^2 .* nA1
          noRotationHere = 1; 
        elseif (p./q)'.*(p./r) <= eps .^ 2 .* nA1
          noRotationHere = 1; 
        else
          r = 1 - r./q;
          p = p ./ q;
          vt = sqrt(4.*conj(p).*p + r.*r);
          c = sqrt(0.5 .* (1 + r./vt));
          s = p./ (vt .* c);
        end
    
        if noRotationHere == 0
          G = mk_givens(c, s, n, j, k);
%          assert(adimat_isunitary(G));
          A = A * G;
          if nargout > 2
            V = full(V * G);
          end
        else
          rcount = rcount - 1;
        end
        
      end
    end
%    fprintf(1, 'end of sweeep %d, number of rotations: %d\n', scount, rcount);

    if nt > 1
      if z(nt) ./ (z(1) + tol) <= tol
        nt = nt - 1;
      end
    end
    
    scount = scount + 1;
    
  end
  
  if nargout > 1
%    assert(adimat_isunitary(V));
  end
  
  if scount > slimit
    error('adimat:onesided_jacobi:too_many_sweeps', ...
          'Too many sweeps (%d) in one-sided Jacobi scheme', scount);
  end

end
% $Id: adimat_onesided_jacobi.m 4162 2014-05-12 07:34:49Z willkomm $
