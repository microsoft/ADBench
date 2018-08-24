% function Z = admMatMultV3TM(A, B)
%
% see also admMatMultV3
%
% Copyright (C) 2014 Johannes Willkomm
%
function Z = admMatMultV3TM(A, B)

  % A is (m x n x k) tensor
  % B is (n x p) matrix
  
  szA = size(A);
  szB = size(B);

  %  fprintf('admMatMultV3TM: (%s) * (%s)\n', mat2str(szA), mat2str(szB)); 
  
  if szA(1) * 1000 < size(A,3)
  
    Z = admMatMultV3TMa(A, B);
  
  else
    
    Z = admMatMultV3TMc(A, B);
  
  end

% $Id: admMatMultV3TM.m 4496 2014-06-13 12:00:01Z willkomm $
