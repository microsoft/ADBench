% function [U S V] = adimat_svd(A)
%
% Compute the SVD of matrix A with the algorithm from [1].
%
% [1] J. C. Nash and S. Shlien, "Simple Algorithms for the Partial
% Singular Value Decomposition", The Computer Journal, 1987.
%
% Copyright 2013 Johannes Willkomm
%
function [U S V] = adimat_svd(A)
  [m n] = size(A);

  if m < n
    % broad matrix handled by recursion
    
    if nargout <= 1
      % just the singular values
      U = adimat_svd(A');
    else
      % full SVD of transposed matrix
      [tmp S V] = adimat_svd(A');
      U = V;
      V = tmp;
      S = S.';
    end
  
  else

    nA1 = norm(A,'fro');
  
    if nargout > 1
      [svals B V nt] = adimat_onesided_jacobi(A, nA1);
    else
      svals = adimat_onesided_jacobi(A, nA1);
    end
  
    neqz = svals ~= 0;
    svals(neqz) = sqrt(svals(neqz));

    if nargout <= 1
      U = svals;
    
    else
      U = B;
      for i=1:nt
        % svals(i) = norm(U(:,i));
        % svals(i) = sqrt(U(:,i)' * U(:,i));
        % assert((svals(i) - norm(U(:,i))) ./ svals(i) < 1e-14)
        if svals(i) ./ (svals(1) + eps) > eps
          U(:,i) = U(:,i) ./ svals(i);
        else
          nt = min(i-1, nt);
        end
      end
      
      S = [diag(svals); zeros(m-n, n)];
      
      if nt == 0
        U = eye(m);
      
      elseif m > nt
        % complete U to an othonormal base
        qualArnoldi = 1;
        count = 1;
        maxArnoldiTries = 20;
        % Using rand: save seed and set to a fixed seed value for reproducible
        % results. However, in RM the seed will ultimately be left in
        % state 1992, sry
        rs = rand('state');
        rand('state', 1992);
        while qualArnoldi ./ nA1 > eps .* 10 && count < maxArnoldiTries
          if count == 1
            Uprelim = [U(:,1:nt) eye(m, m-nt)];
          else
            % fprintf(1, 'adimat_svd: trying again to find a base\n');
            Uprelim = [U(:,1:nt) rand(m, m-nt)];
          end
          [Q H qualArnoldi] = adimat_arnoldi(Uprelim, m, U(:,1:nt));
          count = count + 1;
        end
        U = Q;
        rand('state', rs);
        if count >= maxArnoldiTries
          error('adimat:svd_jacobi:too_many_base_tries', ...
                'Too many tries (%d) to complete the left unitary base', count);
        end
      end
 
      % this will always be fairly good
      % qsvd = norm(U * S * V' - A, 1) ./ norm(A, 1)
      
      % this is the interesting one: much depends on U being unitary
      qsvd = norm(S - U' * A * V, 1) ./ (norm(A, 1) + eps);
      assert(qsvd < eps(class(A)) .* 1000);
      
      % which we can test here
      % qU = norm(U' * U - eye(size(U)))
      
      % not a problem
      % qV = norm(V' * V - eye(size(V)))
    end
  
  end

% $Id: adimat_svd.m 3964 2013-10-31 10:05:18Z willkomm $
