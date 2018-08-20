% function [adj1 adj2] = adimat_a_mrdivide(divident, divisor, adj)
%
% This determines the adjoints of expr = divident / divisor where adj
% is the adjoint of expr.
%
% see also adimat_a_mldivide
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2014 Johannes Willkomm
%
function [adj1 adj2] = adimat_a_mrdivide(divident, divisor, adj)
  if isscalar(divisor)
    res = divident / divisor;
    adj1 = adimat_adjred(divident, adj ./ divisor);
    adj2 = adimat_allsum(-res .* adj ./ divisor);
  else
    [adj2 adj1] = adimat_a_mldivide(divisor.', divident.', adj.');
    adj1 = adj1.';
    adj2 = adj2.';
  end
% $Id: adimat_a_mrdivide.m 4153 2014-05-11 16:35:51Z willkomm $
