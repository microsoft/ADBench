% function [R] = adimat_sqrtm_triu(T)
%
% Compute R = sqrtm(T) of an upper triangular matrix T, as described
% in "A Schur method for the Square Root of a Matrix", Åke Björck,
% 1982.
% 
% This function is used by adimat_sqrtm and adimat_logm.
%
% see also adimat_sqrtm, adimat_logm.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [R] = adimat_sqrtm_triu(T)
  n = size(T,1);

  R = zeros(n);
  R(eye(n) == 1) = sqrt(diag(T));
  
  for d=1:n-1
    for i=1:n-d
      j = i+d;
      uij = T(i,j);
      if d > 1
        uij = uij - R(i,i+1:j-1) * R(i+1:j-1,j);
      end
      uij = uij ./ (R(i,i) + R(j,j));
      R(i,j) = uij;
    end
  end

%  squal = norm(R * R - T)
end
% $Id: adimat_sqrtm_triu.m 3788 2013-06-24 08:18:30Z willkomm $
