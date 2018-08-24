% function z = a_cumsum(adj, ind, a, b)
%
% Copyright (C) 2015 Johannes Willkomm
function z = a_cumsum(adj, ind, a, b)
  if nargin < 4
    b = adimat_first_nonsingleton(a);
  end
  switch ind
   case 1
    J = partial_cumsum(a, b);
    z = reshape(adj(:).' * J, size(a));
   case 2
    z = a_zeros(0);
  end
end
% $Id: a_cumsum.m 4880 2015-02-14 17:16:52Z willkomm $
