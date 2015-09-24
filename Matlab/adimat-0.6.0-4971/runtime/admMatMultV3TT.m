% function Z = admMatMultV3TT(A, B)
%
% see also admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV3TT(A, B)

  % A is (m x n x k) tensor
  % B is (n x p x k) matrix
  
  szA = size(A);
  szB = size(B);

  if szA(1).*szB(2).*9.9 < size(A,3)
  
    if szA(1) < szB(2)
      Z = admMatMultV3TTa(A, B);
    else
      Z = admMatMultV3TTb(A, B);
    end
    
  else
    
    Z = admMatMultV3TTc(A, B);
  
  end

% $Id: admMatMultV3TT.m 4496 2014-06-13 12:00:01Z willkomm $
