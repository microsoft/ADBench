% function [seed] = admCreateCompressedSeedSparse(coloring)
%
%   Create a sparse seed matrix from color vector.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [seed] = admCreateCompressedSeedSparse(coloring)

  ncols = length(coloring);
  ndd = max(coloring);
  
  is = zeros(ncols, 1);
  js = zeros(ncols, 1);
  offs = 0;
  for i=1:ndd
    w = find(coloring == i);
    is(offs+1:offs+length(w)) = w;
    js(offs+1:offs+length(w)) = i;
    offs = offs + length(w);
  end
  
  seed = sparse(is, js, 1, ncols, ndd);
  
% $Id: admCreateCompressedSeedSparse.m 2900 2011-05-13 11:43:26Z willkomm $
