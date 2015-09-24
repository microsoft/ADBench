%
% function r = adimat_adjmultr(val, factor, adj, factor2)
%
%   This determines the adjoint value of val in expr = factor * val *
%   factor2 where adj is the adjoint of expr.
%
%   If val is a scalar return adimat_allsum(adj .* (factor * factor2))
%   otherwise return factor' * adj * factor2'.
%
% see also adimat_adjmultl, adimat_adjmultr, adimat_adjred,
% adimat_allsum
%
% This file is part of the ADiMat runtime environment.
%
function adj = adimat_adjmultm(val, factor, adj, factor2)
  if isscalar(val)
    adj = adimat_allsum(adj .* (factor * factor2));
  else
    adj = factor' * adj * factor2';
  end
% $Id: adimat_adjmultm.m 1764 2010-02-25 19:05:10Z willkomm $
