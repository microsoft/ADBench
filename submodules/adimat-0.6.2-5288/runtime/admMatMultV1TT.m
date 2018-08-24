% function Z = admMatMultV1TT(A, B)
%
% see also admMatMultV1
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV1TT(A, B)

  % A is (k x m x n) tensor
  % B is (k x n x p) tensor
  
  szA = size(A);
  szB = size(B);

  [~, which] = min([szA(2) szB(3) szA(1)]);
  
  switch which
   case 1
    Z = admMatMultV1TTa(A, B);
   case 2
    Z = admMatMultV1TTb(A, B);
   case 3
    Z = admMatMultV1TTc(A, B);
  end

% $Id: admMatMultV1TT.m 4474 2014-06-12 08:31:02Z willkomm $
