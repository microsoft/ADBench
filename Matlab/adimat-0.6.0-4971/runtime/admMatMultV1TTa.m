% function Z = admMatMultV1TTa(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1TTa(A, B)

  % A is (k x m x n) tensor
  % B is (k x n x p) tensor
  
  szA = size(A);
  szB = size(B);

  Z = zeros(szA(1), szA(2), szB(3));

  for k=1:szA(2)
    T = bsxfun(@times, reshape(A(:,k,:), [szA(1) szA(3) 1]), B);
    Z(:,k,:) = sum(T, 2);
  end

% $Id: admMatMultV1TTa.m 4467 2014-06-11 10:44:59Z willkomm $
