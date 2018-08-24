% function [dfargs] = admMergeArgs(derivArgs, funcArgs, independents)
%
% see also admDiffRev, admDiffVFor, admTransform, createFullGradients,
% createSeededGradients, admJacFor, admOptions, adimat_derivclass.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [dfargs] = admMergeArgs(derivArgs, funcArgs, independents)
  dfargs = cell(1, length(funcArgs) + length(derivArgs));
  ai = 1;
  for i=1:length(funcArgs)
    dPos = find(independents == i);
    if ~isempty(dPos)
      dfargs{ai} = derivArgs{dPos};
      ai = ai + 1;
    end
    dfargs{ai} = funcArgs{i};
    ai = ai + 1;
  end

% $Id: admMergeArgs.m 3067 2011-10-09 17:30:55Z willkomm $
