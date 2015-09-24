% function [dfargs] = admMergeArgs2(derivArgs2, derivArgs, funcArgs, independents)
%
% see also admDiffRev, admDiffVFor, admTransform, createFullGradients,
% createSeededGradients, admJacFor, admOptions, adimat_derivclass.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011,2014 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [dfargs] = admMergeArgs2(derivArgs2, derivArgsA, derivArgsB, funcArgs, independents)
  dfargs = cell(1, length(funcArgs) + length(derivArgsA) + length(derivArgsB));
  ai = 1;
  for i=1:length(funcArgs)
    dPos = find(independents == i);
    if ~isempty(dPos)
      dfargs{ai} = derivArgs2{dPos};
      dfargs{ai+1} = derivArgsA{dPos};
      dfargs{ai+2} = derivArgsB{dPos};
      ai = ai + 3;
    end
    dfargs{ai} = funcArgs{i};
    ai = ai + 1;
  end

% $Id: admMergeArgs2.m 4103 2014-05-04 20:29:01Z willkomm $
