% function [g_U U g_S S g_V V] = adimat_g_svd(g_A, A)
%
% When called with 2 output arguments, compute derivatives of s in s =
% svd(A).
%
% When called with 6 output arguments, compute derivatives of U, S,
% and V in [ U S V ] = svd(A).
%
% Also return the function result.
%
% Using the method from Mike Giles, "An extended collection of matrix
% derivative results for forward and reverse mode algorithmic
% differentiation", 2008
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [g_U U g_S S g_V V] = adimat_g_svd(g_A, A)

  if ~isreal(A)
    warning('adimat:for:svd', '%s', ...
            'for complex matrices, the differentiation of svd is not yet supported');
  end
  
  [U S V] = svd(A);
  
  dUSV = U.' * g_A * V;
  
  diagS1 = adimat_safediag(S);
    
  [U S V] = svd(A);
  
  if nargout == 2
  
    %% 
    % compute derivatives of vector of singular values s = svd(A)
  
    g_U = call(@real, call(@adimat_safediag, dUSV));
    U = diagS1;
    
  else
  
    %% 
    % compute derivatives of full decomposition  [U S V] = svd(A)
    
  [m, n] = size(A);
  broad = m <= n;

  F = d_eig_F(diagS1.^2);
  
  if broad 
  
    g_S = [call(@diag, call(@real, call(@adimat_safediag, dUSV))) g_zeros([m, n-m])];
  
    emS1 = repmat(diagS1, [1 m]);

    dP1 = dUSV(1:m, 1:m);
    dP2 = dUSV(1:m, m+1:end);
    S1 = S(1:m, 1:m);
    
    dC = F .* (emS1.' .* dP1 + emS1 .* dP1.');
    g_U = U * dC;
    
    dD1 = F .* (emS1 .* dP1 + emS1.' .* dP1.');
    % dD2 = S1 \ dP2;
    dD2 = dP2;
    neqz = diagS1 ~= 0;
    dD2(neqz,:) = dD2(neqz,:) ./ repmat(diagS1(neqz), [1 n-m]);
    dD = [dD1    -dD2
          dD2.'  g_zeros([n-m, n-m])];
    g_V = V * dD;

  else
    
    g_S = [call(@diag, call(@real, call(@adimat_safediag, dUSV)))
           g_zeros([m-n, n])];
  
    emS1 = repmat(diagS1, [1 n]);

    dP1 = dUSV(1:n, 1:n);
    dP2 = dUSV(n+1:end, 1:n);
    S1 = S(1:n, 1:n);
    
    dC = F .* (emS1 .* dP1 + emS1.' .* dP1.');
    g_V = V * dC;
    
    dD1 = F .* (emS1.' .* dP1 + emS1 .* dP1.');
    % dD2 = S1 \ dP2.';
    dD2 = dP2.';
    neqz = diagS1 ~= 0;
    dD2(neqz,:) = dD2(neqz,:) ./ repmat(diagS1(neqz), [1 m-n]);
    dD = [dD1    -dD2
          dD2.'  g_zeros([m-n, m-n])];
    g_U = U * dD;
    
  end
  
  end

end
% $Id: adimat_g_svd.m 3966 2013-10-31 13:04:34Z willkomm $
