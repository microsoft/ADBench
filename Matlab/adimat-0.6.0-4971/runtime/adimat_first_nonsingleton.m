% function res = adimat_first_nonsingleton(val)
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011,2013 Johannes Willkomm
function res = adimat_first_nonsingleton(val)
  sz = size(val);
  ind = find(sz ~= 1);
  if length(ind) > 0
    res = ind(1);
  else
    res = 1;
  end

% $Id: adimat_first_nonsingleton.m 3901 2013-10-08 09:47:21Z willkomm $
