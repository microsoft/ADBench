% function adj = adimat_min21(val1, val2, adj)
%
% This determines the adjoint of val1 in z = min(val1, val2), where
% the adjoint of z is given as parameter adj.
%
% see also a_mean
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function adj = adimat_min21(val1, val2, adj)
  m = min(val1, val2);
  where = m == val1;
  ties = where & (m == val2);
  adj(~where) = a_zeros(0);
  if any(ties(:))
     warning('adimat:min:ties', 'There are %d ties in the min(x, y) evaluation.', sum(ties(:)));
     adj(ties) = adj(ties) .* 0.5;
  end
  adj = adimat_adjred(val1, adj);
% $Id: adimat_min21.m 3762 2013-06-14 14:53:34Z willkomm $
