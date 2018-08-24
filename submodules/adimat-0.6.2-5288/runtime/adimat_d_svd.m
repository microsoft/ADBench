% function [g_U U d_S S d_V V] = d_svd(d_A, A)
%
% Compute derivatives of U, S, V in [ U S V ] = svd(A).
%
% Using the method from Mike Giles, "An extended collection of matrix
% derivative results for forward and reverse mode algorithmic
% differentiation", 2008
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [d_U U d_S S d_V V] = d_svd(d_A, A)

  if ~isreal(A)
    warning('adimat:vfor:svd', '%s', ...
            'for complex matrices, the differentiation of svd is not yet supported');
  end
  
  [U S V] = svd(A);
  
  dUSV = adimat_mtimes_dv(adimat_mtimes_vd(U.', d_A), V);

  diagS1 = adimat_safediag(S);
  
  ndd = size(d_A, 1);

  [m, n] = size(A);

  if nargout == 2

    %% 
    % compute derivatives of vector of singular values s = svd(A)
  
    d_U = d_zeros(diagS1);
    for i=1:ndd
      dd = adimat_safediag(reshape(real(dUSV(i,:)), [m, n]));
      d_U(i,:) = dd(:).';
    end
    U = diagS1;
    
  else
  
    %% 
    % compute derivatives of full decomposition  [U S V] = svd(A)
    
  broad = m <= n;

  d_S = d_zeros(S);

  F = d_eig_F(diagS1.^2);
  
  if broad
      
    emS1 = repmat(diagS1, [1 m]);

    filler = zeros([m, n-m]);
    for i=1:ndd
      dd = [diag(real(adimat_safediag(reshape(dUSV(i,:), [m, n])))) filler];
      d_S(i,:) = dd(:).';
    end
    
    dP1 = dUSV(:, 1:m, 1:m);
    dP2 = dUSV(:, 1:m, m+1:end);
    S1 = S(1:m, 1:m);
    
    Fr = repmat(reshape(F, [1 m m]), [ndd 1 1]);
    
    dP1T = adimat_opdiff_etrans(dP1);
    % passing F just as a dummy (because it has right size)
    dC = Fr .* (adimat_opdiff_emult_left(emS1.', dP1, F) + adimat_opdiff_emult_left(emS1, dP1T, F));
    d_U = adimat_mtimes_vd(U, dC);
    
    dD1 = Fr .* (adimat_opdiff_emult_left(emS1, dP1, F) + adimat_opdiff_emult_left(emS1.', dP1T, F));
    % dD2 = adimat_mldivide_vd(S1, dP2);
    % dD2 = S1 \ dP2; => dD2 = dP2 ./ repmat(diagS1, [1 n-m]);
    neqz = diagS1 ~= 0;
    dD2 = dP2;
    if any(neqz)
      dD2(:,neqz,:) = adimat_rdivide_dv(dP2(:,neqz,:), repmat(diagS1(neqz), [1 n-m]));
    end
    dD = cat(2, cat(3, dD1, -dD2), ...
             cat(3, adimat_opdiff_etrans(dD2), d_zeros_size([n-m, n-m])));
    d_V = adimat_mtimes_vd(V, dD);
  
  else
  
    emS1 = repmat(diagS1, [1 n]);

    filler = zeros([m-n, n]);
    for i=1:ndd
      dd = [diag(real(adimat_safediag(reshape(dUSV(i,:), [m, n])))) 
            filler];
      d_S(i,:) = dd(:).';
    end
    
    dP1 = dUSV(:, 1:n, 1:n);
    dP2 = dUSV(:, n+1:end, 1:n);
    S1 = S(1:n, 1:n);
    
    Fr = repmat(reshape(F, [1 n n]), [ndd 1 1]);
    
    dP1T = adimat_opdiff_etrans(dP1);
    % passing F just as a dummy (because it has right size)
    dC = Fr .* (adimat_opdiff_emult_left(emS1, dP1, F) + adimat_opdiff_emult_left(emS1.', dP1T, F));
    d_V = adimat_mtimes_vd(V, dC);
    
    dD1 = Fr .* (adimat_opdiff_emult_left(emS1.', dP1, F) + adimat_opdiff_emult_left(emS1, dP1T, F));
    % dD2 = S1 \ dP2.'; => dD2 = dP2.' ./ repmat(diagS1, [1 m-n]);
    % dD2 = adimat_mldivide_vd(S1, adimat_opdiff_etrans(dP2));
    dP2 = adimat_opdiff_etrans(dP2);
    neqz = diagS1 ~= 0;
    dD2 = dP2;
    if any(neqz)
      dD2(:,neqz,:) = adimat_rdivide_dv(dP2(:,neqz,:), repmat(diagS1(neqz), [1 m-n]));
    end
    dD = cat(2, cat(3, dD1, -dD2), ...
             cat(3, adimat_opdiff_etrans(dD2), d_zeros_size([m-n, m-n])));
    d_U = adimat_mtimes_vd(U, dD);
  
  end
end

% $Id: adimat_d_svd.m 3966 2013-10-31 13:04:34Z willkomm $
