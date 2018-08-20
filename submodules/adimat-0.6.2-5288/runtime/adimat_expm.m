% function [z] = adimat_expm(x)
%
% Compute z = expm(x). This is an implementation using Padé
% approximants as given by Higham. This functions is
% differentiation with ADiMat to create the runtime functions
% g_adimat_expm, d_adimat_expm, and a_adimat_expm.
%
% see also g_adimat_expm, d_adimat_expm, a_adimat_expm.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [z] = adimat_expm(x)
  [z] = padeExpm(x);
end
  
function [R] = padeExpm(A)
  global adimat_expm_fast
  
  l = [2.11e-8, 3.56e-4, 1.08e-2, 6.49e-2, ...
       2e-1,    4.37e-1, 7.83e-1, 1.23, ...
       1.78,    2.42, ...
       3.13,    3.9,     4.74,    5.63, ...
       6.56,    7.52,    8.53,    9.56, ...
       1.06e1,  1.17e1 ...
      ];

  b = [64764752532480000, 32382376266240000, 7771770303897600, ...
       1187353796428800, 129060195264000, 10559470521600, 670442572800, 33522128640, ...
       1323241920, 40840800, 960960, 16380, 182, 1];
  
  n1A = norm(A, 1);
  
  lesserM = false;
  
  if adimat_expm_fast
    for m=[3 5 7 9]
      if n1A < l(m)
        [ U V ] = lesserPadeExpm(A, m, b);
        s = 0;
        lesserM = true;
      end
    end
  end
  
  if ~lesserM
    s = max(ceil(log2(n1A/l(13))), 0);
    
    A = A ./ (2^s);
    
    A2 = A*A;
    A4 = A2*A2;
    A6 = A2*A4;
    
    W1 = b(14) .* A6 + b(12) .* A4 + b(10) .* A2;
    W2 = b(8) .* A6 + b(6) .* A4 + b(4) .* A2 + b(2) .* eye(size(A));
    
    Z1 = b(13) .* A6 + b(11) .* A4 + b(9) .* A2;
    Z2 = b(7) .* A6 + b(5) .* A4 + b(3) .* A2 + b(1) .* eye(size(A));
  
    W = A6*W1 + W2;
    U = A*W;
    V = A6*Z1 + Z2;
    
  end
  
  R = (-U + V) \ (U + V);
  
  for i=1:s
    R = R*R;
  end

end

function [U, V] = lesserPadeExpm(A, m, b)
  top = (m-1) ./ 2;
  V = b(1) .* eye(size(A));
  U = b(2) .* eye(size(A));
  A2 = A * A;
  X = A2;
  for k=1:top
    V = V + b(2*k+1) .* X;
    U = U + b(2*k+2) .* X;
    X = X * A2;
  end
  U = A * U;
end

% $Id: adimat_expm.m 3673 2013-05-27 12:17:48Z willkomm $
