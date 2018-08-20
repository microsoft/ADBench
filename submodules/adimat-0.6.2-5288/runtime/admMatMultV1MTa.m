% function Z = admMatMultV1MT(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1MT(A, B)

  % A is (m x n) matrix
  % B is (k x n x p) tensor
  
  szA = size(A);
  szB = size(B);

  Z = zeros([szB(1), szA(1), szB(3)]);
  for k=1:szB(1)
    Z(k,:,:) = A * shiftdim(B(k,:,:), 1);
  end

% $Id: admMatMultV1MTa.m 4567 2014-06-18 19:04:48Z willkomm $
