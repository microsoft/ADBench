% function r = adimat_adjmultr(val, factor, adj)
%
%   This determines the adjoint value of val in expr = factor * val
%   where adj is the adjoint of expr.
%
%   If val is a scalar return adimat_allsum(adj .* factor)
%   otherwise return factor' * adj.
%
% see also adimat_adjmultl, adimat_adjmultm, adimat_adjred,
% adimat_allsum
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = adimat_adjmultr(val, factor, adj, factor2)
  if isscalar(val)
    adj = adimat_allsum(adj .* factor);
  else
    adj = factor.' * adj;
  end
% $Id: adimat_adjmultr.m 3919 2013-10-11 15:12:04Z willkomm $
