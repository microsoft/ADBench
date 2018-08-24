% function r = adimat_end(arr, k, n)
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_end(arr, k, n)
  sz = size(arr);
  if k == n && length(sz) > n
    r = prod(sz(n:end));
  else
    r = sz(k);
  end

% $Id: adimat_end.m 3827 2013-07-24 15:19:52Z willkomm $
