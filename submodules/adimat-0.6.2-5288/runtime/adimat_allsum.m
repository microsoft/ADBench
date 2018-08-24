% function r = adimat_allsum(obj)
%
%   this function computes the sum of all values in obj
%   if obj is a scalar return obj
%   if obj is a vector return sum(obj)
%   if obj is a matrix return sum(sum(obj))
%
% see also adimat_adjred, adimat_adjmultl, adimat_adjmultr
%
% This file is part of the ADiMat runtime environment
% This function is deprecated.
function r = adimat_allsum(obj)
  r = sum(obj(:));

% $Id: adimat_allsum.m 2207 2010-09-02 15:02:42Z willkomm $
