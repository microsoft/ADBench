% function [seedMatrix jPattern coloring] = ...
%      admMakeSeedMatrixRev(seedMatrix, nCompInputs, admOpts)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function [seedMatrix jPattern coloring] = ...
      admMakeSeedMatrixRev(seedMatrix, nCompOutputs, admOpts)

  admOpts.jac_nzpattern = admOpts.jac_nzpattern.';
  admOpts.JPattern = admOpts.JPattern.';
  [seedMatrix jPattern coloring] = admMakeSeedMatrixFor(seedMatrix, nCompOutputs, admOpts);
  if ~isempty(coloring)
    seedMatrix = seedMatrix.';
  end
  
% $Id: admMakeSeedMatrixRev.m 4605 2014-07-07 14:17:45Z willkomm $
