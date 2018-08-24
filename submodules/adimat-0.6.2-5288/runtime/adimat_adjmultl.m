% function r = adimat_adjmultl(val, adj, factor)
%
%   This determines the adjoint value of val in expr = val * factor
%   where adj is the adjoint of expr.
%
%   If val is a scalar return adimat_allsum(adj .* factor)
%   otherwise return adj * factor'.
%
% see also adimat_adjmultm, adimat_adjmultr, adimat_adjred, adimat_allsum
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = adimat_adjmultl(val, adj, factor)
  if isscalar(val)
%    fprintf(2, 'admiat: reducing %d x %d adjoint\n', size(incr, 1), size(incr, 2));
    adj = adimat_allsum(adj .* factor);
  else
    adj = adj * factor.';
  end

% $Id: adimat_adjmultl.m 3919 2013-10-11 15:12:04Z willkomm $
