% function [U d_S S V] = d_svd_d2(d_A, A)
%
% Compute derivatives of S in [ U S V ] = svd(A).
%
% Using the method from Mike Giles, "An extended collection of matrix
% derivative results for forward and reverse mode algorithmic
% differentiation", 2008
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [U d_S S V] = d_svd_d2(d_A, A)

  if ~isreal(A)
    warning('adimat:vfor:svd', '%s', ...
            'for complex matrices, the differentiation of svd is not yet supported');
  end
  
  [m, n] = size(A);
  broad = m <= n;

  [U S V] = svd(A);
  
  dUSV = adimat_mtimes_dv(adimat_mtimes_vd(U.', d_A), V);

  ndd = size(d_A, 1);

  d_S = d_zeros(S);

  if broad
      
    filler = zeros([m, n-m]);
    for i=1:ndd
      dd = [diag(real(adimat_safediag(reshape(dUSV(i,:), [m, n])))) filler];
      d_S(i,:) = dd(:).';
    end
    
  else
  
    filler = zeros([m-n, n]);
    for i=1:ndd
      dd = [diag(real(adimat_safediag(reshape(dUSV(i,:), [m, n])))) 
            filler];
      d_S(i,:) = dd(:).';
    end
    
  end
end
% $Id: adimat_d_svd_d2.m 3940 2013-10-16 10:28:07Z willkomm $
