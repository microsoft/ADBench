% function adj = adimat_a_mrdividel(divident, divisor, adj)
%
% This determines the adjoint of divident in expr = divident / divisor
% where adj is the adjoint of expr.
%
% see also adimat_a_mldivider
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2014 Johannes Willkomm
%
function adj = adimat_a_mrdividel(divident, divisor, adj)
  if isscalar(divisor)
    adj = adimat_adjred(divident, adj ./ divisor);
  else
    adj = adimat_a_mldivider(divisor.', divident.', adj.').';
  end
% $Id: adimat_a_mrdividel.m 4153 2014-05-11 16:35:51Z willkomm $
