% function Z = admMatMultV1TTc(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1TTc(A, B)

  % A is (k x m x n) tensor
  % B is (k x n x p) tensor
  
  szA = size(A);
  szB = size(B);

  Z = zeros(szA(1), szA(2), szB(3));

  for k=1:szA(1)
    Z(k,:,:) = shiftdim(A(k,:,:),1) * shiftdim(B(k,:,:),1);
  end

% $Id: admMatMultV1TTc.m 4496 2014-06-13 12:00:01Z willkomm $
