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

  if szB(2) == 1
  
    Z = admMatMultV1MTp(A, B);
  
  elseif szB(1) < szB(3)
    
    Z = admMatMultV1MTa(A, B);
   
  else

    Z = admMatMultV1MTb(A, B);
    
  end
  
% $Id: admMatMultV1MT.m 4567 2014-06-18 19:04:48Z willkomm $
