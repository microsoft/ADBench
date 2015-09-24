%
% function r = adimat_repind(nd, dim, len)
%  generate vector of ones of size [1 nd] and set r(dim) = len
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_repind(nd, dim, len)
  r = ones(1, nd);
  r(dim) = len;

% $Id: adimat_repind.m 1764 2010-02-25 19:05:10Z willkomm $
