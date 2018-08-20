% function z = admMatMultV3(A, B)
%
% see also admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV3MT(A, B)

  % A is (m x n) matrix
  % B is (n x p x k) tensor
  
  szA = size(A);
  szB = size(B);

  Z = reshape( A * reshape(B, [szB(1), szB(2) .* size(B,3)]), [szA(1), szB(2), size(B,3)] );

% $Id: admMatMultV3MT.m 4496 2014-06-13 12:00:01Z willkomm $
