% function z = adimat_padarray(z, padcnt)
%
% Successively pad array z with padcnt(dim) slices of zeros along each
% dimension dim.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function z = adimat_padarray(z, padcnt)
  for dim=1:length(size(padcnt))
    sz = size(z);
    sz(dim) = padcnt(dim);
    padding = zeros(sz);
    z = cat(dim, z, padding);
  end

% $Id: adimat_padarray.m 3670 2013-05-27 08:20:23Z willkomm $
