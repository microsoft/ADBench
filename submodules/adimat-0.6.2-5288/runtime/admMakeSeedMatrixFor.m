% function [seedMatrix coloring jPattern] = ...
%      admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function [seedMatrix coloring jPattern] = ...
      admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts)

  coloring = [];

  jPattern = admOpts.jac_nzpattern;
  if isempty(jPattern)
    jPattern = admOpts.JPattern;
  end
  
  if ~isempty(jPattern)

    % use compression

    if isa(seedMatrix, 'char')
      coloringFunctionName = seedMatrix;
      admOpts.coloringFunction = str2func(seedMatrix);
    elseif isa(seedMatrix, 'function_handle')
      coloringFunctionName = func2str(seedMatrix);
      admOpts.coloringFunction = seedMatrix;
    elseif isa(admOpts.coloringFunction, 'function_handle')
      coloringFunctionName = func2str(admOpts.coloringFunction);
    elseif isa(admOpts.coloringFunction, 'char')
      coloringFunctionName = admOpts.coloringFunction;
    else
      error('adimat:admDiff:noColoringFunction', ...
            ['Options field coloringFunction must be either a function name'...
             ' or a function handle, but is of class "%s".'], ...
            class(admOpts.coloringFunction));
    end

    [compressedSeed coloring] = admColorSeed(jPattern, admOpts);
    seedMatrix = compressedSeed;
    
    fprintf(admLogFile('coloring'), 'Compressed seed matrix: %dx%d\n', ...
            size(seedMatrix, 1), size(seedMatrix, 2));
  
  end

% $Id: admMakeSeedMatrixFor.m 4605 2014-07-07 14:17:45Z willkomm $
