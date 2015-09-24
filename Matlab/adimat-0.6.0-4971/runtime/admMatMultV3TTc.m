% function Z = admMatMultV3TTa(A, B)
%
% see also admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV3TTc(A, B)

  % A is (m x n x k) tensor
  % B is (n x p x k) matrix
  
  szA = size(A);
  szB = size(B);

  Z = zeros(szA(1), szB(2), size(A,3));

  for k=1:size(A,3)
    Z(:,:,k) = A(:,:,k) * B(:,:,k);
  end

% $Id: admMatMultV3TTc.m 4496 2014-06-13 12:00:01Z willkomm $
