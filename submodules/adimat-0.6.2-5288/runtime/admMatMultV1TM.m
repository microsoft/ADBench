% function Z = admMatMultV1TM(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1TM(A, B)

  % A is (k x m x n) tensor
  % B is (n x p) matrix
  
  szA = size(A);
  szB = size(B);

  Z = reshape(reshape(A, [szA(1) .* szA(2), szA(3)]) * B, [szA(1), szA(2), szB(2)]);

% $Id: admMatMultV1TM.m 4467 2014-06-11 10:44:59Z willkomm $
