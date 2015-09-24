% function [adj U S V] = a_svd_010(adj, A)
%
% Compute adjoint of A in [ U S V ] = svd(A), given the adjoint of S.
%
% Using the method from Mike Giles, "An extended collection of matrix
% derivative results for forward and reverse mode algorithmic
% differentiation", 2008
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [adj U S V] = a_svd_010(adj, A)
  
  if ~isreal(A)
    warning('adimat:rev:svd', '%s', ...
            'for complex matrices, the differentiation of svd is not yet supported');
  end
  
  [ U S V ] = svd(A);

  [m, n] = size(A);
  broad = m <= n;

  if broad 
    adj = [call(@diag, call(@adimat_safediag, adj)) a_zeros(zeros([m, n-m]))];
  else
    adj = [call(@diag, call(@adimat_safediag, adj))
           a_zeros(zeros([m-n, n]))];
  end
    
  adj = U * adj * V.';
end
% $Id: a_svd_010.m 3940 2013-10-16 10:28:07Z willkomm $
