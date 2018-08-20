% function [Hess] = admUncompressHess(compressedHess, pattern, coloring)
%
% Uncompress compressedHess according to pattern and coloring.
%
% Copyright © 2014 Johannes Willkomm
%
% This file is part of the ADiMat runtime environment
%
function [Hess] = admUncompressHess(compressedHess, pattern, coloring, V, seedW)

  sz = size(pattern);
  
  Hess = zeros(size(compressedHess, 1), size(seedW, 2), sz(1));
  
  Vpat = (V ~= 0);
  
  for k=1:size(compressedHess, 3)
    tpat = Vpat * double(pattern(k,:).') * pattern(k,:);
    Hess(:,:,k) = admUncompressJac(compressedHess(:,:,k), tpat, coloring, seedW);
  end
  
%  $Id: admUncompressHess.m 4609 2014-07-09 13:28:38Z willkomm $
