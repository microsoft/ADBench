% function adj = adimat_max22(val1, val2, adj)
%
% This determines the adjoint of val2 in z = max(val1, val2), where
% the adjoint of z is given as parameter adj.
%
% see also a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function adj = adimat_max22(val1, val2, adj)
  m = max(val1, val2);
  where = m == val2;
  ties = where & (m == val1);
  adj(~where) = a_zeros(0);
  if any(ties(:))
     warning('adimat:max:ties', 'There are %d ties in the max(x, y) evaluation.', sum(ties(:)));
     adj(ties) = adj(ties) .* 0.5;
  end
  adj = adimat_adjred(val2, adj);
% $Id: adimat_max22.m 3973 2013-11-06 09:23:26Z willkomm $
