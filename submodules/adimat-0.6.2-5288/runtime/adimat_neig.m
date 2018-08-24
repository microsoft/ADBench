% function [V D] = adimat_neig(A)
% 
% Return eigenvectors in a normalized form: first component is always
% positive.
%
% Copyright (C) 2015 Johannes Willkomm
function [V D] = adimat_neig(A)
  [V D] = eig(A);
  for k=1:size(V,2)
    V(:,k) = sign(V(1,k)) .* V(:,k);
  end
% $Id: adimat_neig.m 5004 2015-05-18 21:20:08Z willkomm $
