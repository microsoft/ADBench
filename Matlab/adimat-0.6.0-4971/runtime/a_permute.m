% function adj = a_permute(adj, ind, a, b)
%
% Copyright (C) 2015 Johannes Willkomm
function adj = a_permute(adj, ind, a, b)
  switch ind
   case 1
    adj = ipermute(adj, b);
   otherwise
    adj = a_zeros(0);
  end
end
% $Id$
