% function Z = admMatMultV1TTb(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1TTb(A, B)

  % A is (k x m x n) tensor
  % B is (k x n x p) tensor
  
  szA = size(A);
  szB = size(B);

  Z = zeros(szA(1), szA(2), szB(3));

  for k=1:szB(3)
    T = bsxfun(@times, A, reshape(B(:,:,k), [szA(1) 1 szB(2)]));
    Z(:,:,k) = sum(T, 3);
  end

% $Id: admMatMultV1TTb.m 4467 2014-06-11 10:44:59Z willkomm $
