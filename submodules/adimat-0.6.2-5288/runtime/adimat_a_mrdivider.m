% function adj = adimat_a_mrdivider(divident, divisor, adj)
%
% This determines the adjoint of divisor in expr = divident / divisor
% where adj is the adjoint of expr.
%
% see also adimat_a_mldividel
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2014 Johannes Willkomm
%
function adj = adimat_a_mrdivider(divident, divisor, adj)
  if isscalar(divisor)
    res = divident / divisor;
    adj = adimat_allsum(-res .* adj ./ divisor);
  else
    adj = adimat_a_mldividel(divisor.', divident.', adj.').';
  end
% $Id: adimat_a_mrdivider.m 4153 2014-05-11 16:35:51Z willkomm $
