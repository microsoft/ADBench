% function [a_A U S V] = a_svd_111(a_U, a_S, a_V, A)
%
% Compute adjoint of A in [ U S V ] = svd(A), where a_U, a_S, and a_V
% are the adjoints of U, S, and V, resp.
%
% Using the method from Mike Giles, "An extended collection of matrix
% derivative results for forward and reverse mode algorithmic
% differentiation", 2008, adding in the homework that was left to
% do there.
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [a_A U S V] = a_svd_111(a_U, a_S, a_V, A)

  if ~isreal(A)
    warning('adimat:rev:svd', '%s', ...
            'for complex matrices, the differentiation of svd is not yet supported');
  end
  
  [m, n] = size(A);
  broad = m <= n;
  
  [U S V] = svd(A);
  
  diagS1 = adimat_safediag(S);
    
  F = d_eig_F(diagS1.^2);
    
  if broad 
  
    S1 = S(1:m, 1:m);
    emS1 = repmat(diagS1, [1 m]);

    a_C = U.' * a_U;

    a_CF = a_C .* F;
    
    % X * S1.' == emS1.' .* X,  X.' * S1 == emS1.' .* X.'
    %    a_P1 =        a_CF * S1.';
    %    a_P1 = a_P1 + a_CF.' * S1;
    a_P1 =        emS1.' .* a_CF;
    a_P1 = a_P1 + emS1.' .* a_CF.';
    
    a_D = V.' * a_V;

    a_D1 = a_D(1:m, 1:m);
    a_D2 = -a_D(1:m, m+1:end) + a_D(m+1:end, 1:m).';
    %  a_D3 = a_D(m+1:end, m+1:end);
    
    a_D1F = a_D1 .* F;
    
    % S1.' * X == emS1 .* X,  S1 * X.' == emS1 .* X.'
    % a_P1 = a_P1 + S1.' * a_D1F;
    % a_P1 = a_P1 + S1 * a_D1F.';
    a_P1 = a_P1 + emS1 .* a_D1F;
    a_P1 = a_P1 + emS1 .* a_D1F.';
    
    % a_P2 = inv(S1).' * a_D2;
    a_P2 = a_D2;
    neqz = diagS1 ~= 0;
    a_P2(neqz,:) = a_D2(neqz,:) ./ repmat(diagS1(neqz), [1 n-m]);
    
    a_P = [a_P1 a_P2];
    
    a_A = U * a_P * V.';

    pad_a_S = [call(@diag, call(@adimat_safediag, a_S)) a_zeros(zeros([m, n-m]))];
    
  else
    
    S1 = S(1:n, 1:n);
    emS1 = repmat(diagS1, [1 n]);

    a_C = V.' * a_V;

    a_CF = a_C .* F;
    
    a_P1 =        emS1.' .* a_CF;
    a_P1 = a_P1 + emS1.' .* a_CF.';
    
    a_D = U.' * a_U;

    a_D1 = a_D(1:n, 1:n);
    a_D2 = -a_D(1:n, n+1:end) + a_D(n+1:end, 1:n).';
    %  a_D3 = a_D(n+1:end, n+1:end);
    
    a_D1F = a_D1 .* F;
    
    a_P1 = a_P1 + emS1 .* a_D1F;
    a_P1 = a_P1 + emS1 .* a_D1F.';
    
    % a_P2 = inv(S1).' * a_D2;
    a_P2 = a_D2;
    neqz = diagS1 ~= 0;
    a_P2(neqz,:) = a_D2(neqz,:) ./ repmat(diagS1(neqz), [1 m-n]);
    
    a_P = [a_P1 a_P2];
    
    a_A = U * a_P.' * V.';

    pad_a_S = [call(@diag, call(@adimat_safediag, a_S))
               a_zeros(zeros([m-n, n]))];
 
  end

  a_A = a_A + U * pad_a_S * V.';
  
end
