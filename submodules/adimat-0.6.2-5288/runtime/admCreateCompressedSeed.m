%
% function [seed] = admCreateCompressedSeed(coloring)
%
%   Create a sparse seed matrix from color vector.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [seed] = admCreateCompressedSeed(coloring)

  ncols = length(coloring);
  ndd = max(coloring);
  ssz = [ncols, ndd];
  
  seed = zeros(ssz);
  for i=1:ndd
    seed(coloring==i,i) = 1;
  end
  
% $Id: admCreateCompressedSeed.m 2900 2011-05-13 11:43:26Z willkomm $
