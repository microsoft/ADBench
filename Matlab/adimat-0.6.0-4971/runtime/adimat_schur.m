function [U T] = adimat_schur(A)
   % 1) Numerically, using QR algorithm
   %  [U T] = adimat_qr_shifts(A, eps .* 10, 75);

   nA1 = norm(A, 1);

   % 2) Constructing a Schur decomposition from the list eigenvalues
   % 
   n = size(A,1);
     
   l = eig(A);

   U = eye(n);
   T = zeros(n);
   
   backlog = 0;

   rs = rand('state');
   rand('state', 2992);

   for i=1:n
     lambda = l(i);

     if abs(lambda) ./ nA1 < eps && false
       % bad idea
       
       % skip over zero eigenvalues, whos part of the matrix will be
       % cancelled out as soon as we hit a non-zero one
       backlog = backlog + 1
       
     else
     
       I = i - backlog;
       k = n - I + 1;
       
       Ak = A(I:n,I:n);
       
       v = adimat_eigenvector(Ak, lambda);
       
       % qeigv = norm(Ak * v - lambda * v) ./ norm(v)
       % qeigv = norm((Ak - lambda * eye(size(Ak))) * v) ./ norm(v)
       
       %         hkkm1 = inf;
       %         while hkkm1 .* max(abs(l)) > eps .* 1000

       Qkprelim = [v rand(k, k-1)];
       [Qk H hkkm1] = adimat_arnoldi(Qkprelim, k, v);

       %         end

       Q = eye(n);
       Q(I:n,I:n) = Qk;
       
       U = U * Q;
       A = Q' * A * Q;
     
       backlog = 0;
     end

   end
   
   qT = norm(tril(A, -1)) ./ (nA1 + eps);

   if qT > eps .* 1e2
     warning('adimat:schur:inaccurate', 'Large error in Schur decomposition: %g', qT);
   end
   if qT > eps .* 1e4
     warning('adimat:schur:failure', 'Very large error in Schur decomposition: %g', qT);
   end
   
   T = triu(A);

   rand('state', rs);
       
end
