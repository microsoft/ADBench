% function [seed coloring] = admColorSeed(pattern, opts)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function [seed coloring] = admColorSeed(pattern, opts)
  if nargin < 2
    opts = admOptions();
  end
  
  if isempty(opts.coloring)
    if isempty(opts.coloringFunction)
      opts.coloringFunction = 'cpr';
    end
    colFunc = admGetFunc(opts.coloringFunction);
    ncols = size(pattern, 1);
    colFunColorArg = opts.coloringFunctionColorArgNum;
    [colResults{1:colFunColorArg}] = colFunc(pattern, opts.coloringFunctionArgs{:});
    coloring = colResults{colFunColorArg};
    fprintf(admLogFile('coloring'), 'Colored the pattern with %d colors\n', ...
            max(coloring));
  else
    coloring = opts.coloring;
    if length(coloring) ~= size(pattern, 2)
      error('adimat:admDiff:wrongColoringSize', ...
            'The coloring must be a vector of length %d columns, but it has length %d.', ...
            size(pattern, 2), length(coloring))
    end
  end    

  seed = admCreateCompressedSeedSparse(coloring);

% $Id: admColorSeed.m 4604 2014-07-07 12:46:50Z willkomm $
