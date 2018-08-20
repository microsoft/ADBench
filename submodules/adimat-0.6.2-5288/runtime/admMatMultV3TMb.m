% function Z = admMatMultV3TMb(A, B)
%
% see also admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV3TMb(A, B)

  % A is (m x n x k) tensor
  % B is (n x p) matrix
  
  szA = size(A);
  szB = size(B);

  Z = zeros([szA(1), szB(2), size(A,3)]);

  B = repmat(B, [ 1 1 size(A,3)]);
  
  for k=1:szB(2)
    T = bsxfun(@times, A, reshape(B(:,k,:), [1 szB(1) size(A,3)]));
    Z(:,k,:) = sum(T, 2);
  end

% $Id: admMatMultV3TMb.m 4496 2014-06-13 12:00:01Z willkomm $
