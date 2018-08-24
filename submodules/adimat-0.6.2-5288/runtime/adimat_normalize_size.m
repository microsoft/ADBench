% function sz = adimat_normalize_size(sz)
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2015 Johannes Willkomm 
function sz = adimat_normalize_size(sz)
  nones = sz ~= 1;
  if any(nones)
    last = max(2, max(find(nones)));
    sz = sz(1:last);
  else
    sz = sz(1:2);
  end
end
% $Id: adimat_normalize_size.m 4948 2015-03-02 13:08:45Z willkomm $
