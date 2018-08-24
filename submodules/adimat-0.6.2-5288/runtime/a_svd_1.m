% function [adj] = a_svd_1(adj, A)
%
% Compute adjoint of A in s = svd(A), given the adjoint of s.
%
% Using the method from Mike Giles, "An extended collection of matrix
% derivative results for forward and reverse mode algorithmic
% differentiation", 2008
%
% Copyright 2012,2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

function [adj V] = a_svd_1(adj, A)
  
  if ~isreal(A)
    warning('adimat:rev:svd', '%s', ...
            'for complex matrices, the differentiation of svd is not yet supported');
  end
  
  [ U S V ] = svd(A);

  [m, n] = size(A);
  broad = m <= n;

  adj = call(@diag, adj);
  
  if broad 
    adj = [adj a_zeros(zeros([m, n-m]))];
  else
    adj = [adj
           a_zeros(zeros([m-n, n]))];
  end
    
  adj = U * adj * V.';
  adj = call(@real, adj);

end
% $Id: a_svd_1.m 3940 2013-10-16 10:28:07Z willkomm $
