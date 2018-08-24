% function [V D U]= adimat_lreigs(A, varargin)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm
function [V D U]= adimat_lreigs(A, varargin)
  [U D] = eigs(A, varargin{:});
  k = size(U, 2);
  [V, D2] = eigs(A.', varargin{:});
  V = V.';
  % this test is meant to detect cases were eigs(A.') returns
  % eigenvalues in a completely different order than eigs(A), hence
  % the tolerance is relatively loose
  if relMaxNorm(diag(adimat_value(D)), diag(adimat_value(D2))) < eps .* 1e3
  else
    warning(['The eigenvalues returned bei eigs(A.'') do not match\n' ...
             'those of eigs(A): rel. err. is %g. I''m going to compute left eigenvectors\n'...
             'individualy now.'], relMaxNorm(diag(D), diag(D2)));
    for i=1:k
      [V(i,:) l2] = adimat_leigvect(A, D(i,i), U(:,i));
      assert(relMaxNorm(l2, D(i,i)) < eps .* 1e2)
    end
  end
  V = diag(diag(V*U)) \ V;
% $Id: adimat_lreigs.m 5060 2015-12-03 07:55:47Z willkomm $
