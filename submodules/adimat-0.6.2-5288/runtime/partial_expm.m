% function [partial z] = partial_expm(x, base)
%
% Compute partial derivative of z = expm(x). Also return the function
% result z. partial is multiplied by base, if base is ommited, use
% base = eye(numel(x));
%
% see also g_expm, a_expm
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_expm(x, base)
  if nargin < 2
    base = eye(numel(x));
  end

  ndd = size(base, 2);
  partial = zeros(numel(x), ndd);
  
  E = zeros(size(x));
  for i=1:ndd
    E(:) = base(:, i);
    [tmp z] = diff_padeExpm(x, E);
    partial(:, i) = tmp(:);
  end
  
end
  
function [L R] = diff_padeExpm(A, E)
  global adimat_partial_expm_fast
  
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
  
  if adimat_partial_expm_fast
    for m=[3 5 7 9]
      if n1A < l(m)
        [ L_U U L_V V ] = diff_lesserPadeExpm(A, E, m, b);
        s = 0;
        lesserM = true;
      end
    end
  end
  
  if ~lesserM
    s = max(ceil(log2(n1A/l(13))), 0);
    
    A = A ./ (2^s);
    E = E ./ (2^s);
    
    A2 = A*A;
    A4 = A2*A2;
    A6 = A2*A4;
    
    M2 = A*E + E*A;
    M4 = A2*M2 + M2*A2;
    M6 = A4*M2 + M4*A2;
    
    W1 = b(14) .* A6 + b(12) .* A4 + b(10) .* A2;
    W2 = b(8) .* A6 + b(6) .* A4 + b(4) .* A2 + b(2) .* eye(size(A));
    
    Z1 = b(13) .* A6 + b(11) .* A4 + b(9) .* A2;
    Z2 = b(7) .* A6 + b(5) .* A4 + b(3) .* A2 + b(1) .* eye(size(A));
  
    W = A6*W1 + W2;
    U = A*W;
    V = A6*Z1 + Z2;
    
    L_W1 = b(14) .* M6 + b(12) .* M4 + b(10) .* M2;
    L_W2 = b(8) .* M6 + b(6) .* M4 + b(4) .* M2;
    
    L_Z1 = b(13) .* M6 + b(11) .* M4 + b(9) .* M2;
    L_Z2 = b(7) .* M6 + b(5) .* M4 + b(3) .* M2;
  
    L_W = A6*L_W1 + M6*W1 + L_W2;
    L_U = A*L_W + E*W;
    L_V = A6*L_Z1 + M6*Z1 + L_Z2;
  
  end
  
  R = (-U + V) \ (U + V);
  L = (-U + V) \ (L_U + L_V + (L_U - L_V)*R);
  
  for i=1:s
    L = R*L + L*R;
    R = R*R;
  end

end
  
% function [U, V] = lesserPadeExpm(A, m, b)
%   top = (m-1) ./ 2;
%   V = b(1) .* eye(size(A));
%   U = b(2) .* eye(size(A));
%   A2 = A * A;
%   X = A2;
%   for k=1:top
%     V = V + b(2*k+1) .* X;
%     U = U + b(2*k+2) .* X;
%     X = X * A2;
%   end
%   U = A * U;
% end

function [L_U, U, L_V, V] = diff_lesserPadeExpm(A, E, m, b)
  top = (m-1) ./ 2;
  L_V = zeros(size(A));
  V = b(1) .* eye(size(A));
  L_U = zeros(size(A));
  U = b(2) .* eye(size(A));
  L_A2 = A * E + E * A;
  A2 = A * A;
  L_X = L_A2;
  X = A2;
  for k=1:top
    L_V = L_V + b(2*k+1) .* L_X;
    V = V + b(2*k+1) .* X;
    L_U = L_U + b(2*k+2) .* L_X;
    U = U + b(2*k+2) .* X;
    L_X = L_X * A2 + X * L_A2;
    X = X * A2;
  end
  L_U = E * U + A * L_U;
  U = A * U;
end

% $Id: partial_expm.m 3783 2013-06-20 13:27:02Z willkomm $
