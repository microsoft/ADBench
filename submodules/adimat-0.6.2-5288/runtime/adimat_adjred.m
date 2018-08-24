% function r = adimat_adjred(val, adj)
%   This determines the adjoint value of val, given as parameter adj.
%
%   If val is a scalar return adimat_allsum(adj),
%   otherwise return adj.
%
% see also adimat_allsum, adimat_adjmultl, adimat_adjmultr
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = adimat_adjred(val, adj)
  if isscalar(val)
    % Octave defines isscalar(x) as numel(x) == 1, so we can't use
    % this here!
    if any(size(adj) ~= 1)
      adj = sum(adj(:));
    end
  end

% $Id: adimat_adjred.m 3919 2013-10-11 15:12:04Z willkomm $
