% function x = adimat_cumsum(x, dim)
%
% ADiMat replacement function for cumsum
%
% Copyright (C) 2015 Johannes Willkomm
function x = adimat_cumsum(x, dim)
  if nargin < 2 || ischar(dim)
    dim = adimat_first_nonsingleton(x);
  end
  len = size(x, dim);
  inds = repmat({':'}, [length(size(x)), 1]);
  inds1 = inds;
  for k=2:len
    inds1{dim} = k-1;
    inds{dim} = k;
    x(inds{:}) = x(inds{:}) + x(inds1{:});
  end
end
% $Id: adimat_cumsum.m 4957 2015-03-02 14:58:00Z willkomm $
