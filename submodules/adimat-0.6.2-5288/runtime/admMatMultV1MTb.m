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

  szB3 = 1;
  if length(szB) > 2
    szB3 = szB(3);
  end
  
  At = A.';
  
  Z = zeros([szB(1), szA(1), szB3]);
  for k=1:szB3
    Z(:,:,k) = B(:,:,k) * At;
  end

% $Id: admMatMultV1MTb.m 4874 2015-02-14 13:20:43Z willkomm $
