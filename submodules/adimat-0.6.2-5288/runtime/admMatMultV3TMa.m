% function Z = admMatMultV3TMa(A, B)
%
% see also admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV3TMa(A, B)

  % A is (m x n x k) tensor
  % B is (n x p) matrix
  
  szA = size(A);
  szB = size(B);

  Bt = B.';
  
  Z = zeros([szA(1), szB(2), size(A,3)]);
  for k=1:szA(1)
    Z(k,:,:) = Bt * shiftdim(A(k,:,:), 1);
  end

% $Id: admMatMultV3TMa.m 4496 2014-06-13 12:00:01Z willkomm $
