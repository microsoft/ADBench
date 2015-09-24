% function res = shiftedbsx(v1, v2)
%
% Copyright (C) 2014 Johannes Willkomm
%
function v1 = shiftedbsx(handle, v1, v2)
  n = 1;
  sz1 = size(v1);
  sz2 = size(v2);
  while n <= length(sz1) && n <= length(sz2) && sz1(n) == 1 && sz2(n) == 1
    n = n + 1;
  end
  n = n - 1;
  if n > 0
    v1 = shiftdim(v1, n);
    v2 = shiftdim(v2, n);
  end
  v1 = bsxfun(handle, v1, v2);
% $Id: shiftedbsx.m 4493 2014-06-13 09:15:36Z willkomm $
