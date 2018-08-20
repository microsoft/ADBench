% function [V D] = adimat_neigs(A, k?, sigma?, opts?)
% 
% Return eigenvectors from eigs in a normalized form: first component
% is always positive.
%
% Copyright (C) 2015 Johannes Willkomm
function [V D] = adimat_neigs(A, varargin)
  [V D] = eigs(A, varargin{:});
  for k=1:size(V,2)
    V(:,k) = sign(V(1,k)) .* V(:,k);
  end
% $Id: adimat_neigs.m 5004 2015-05-18 21:20:08Z willkomm $
