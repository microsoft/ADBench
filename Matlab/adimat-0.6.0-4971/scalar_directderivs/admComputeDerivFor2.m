% function [Jacobian, varargout] = ...
%      admComputeDerivFor(diffFunction, seedV, seedW, ...
%                         independents, dependents, fNargout, varargin)
%
% Compute derivatives in second order FM with RE scalar_directderivs.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [Hessian, Jacobian, varargout] = ...
      admComputeDerivFor2(diffFunction, seedV, seedW, ...
                          independents, dependents, ...
                          fNargout, varargin)
  
  funcArgs = varargin;
  
  nActArgs = length(independents);
  nActResults = length(dependents);

  nDFResults = fNargout + 3 .* nActResults;

  actOutIndices = admDerivIndices(dependents);
  hessIndices = actOutIndices + (0:2:2.*length(actOutIndices)-2);
  jacIndices = hessIndices + 1;
  allJacIndices = [hessIndices + 1 hessIndices + 2];
  actOutIndices = union(hessIndices, allJacIndices);
  nactOutIndices = setdiff(1:nDFResults, actOutIndices);

  Jacobian = [];
  Hessian = [];

  for i=1:size(seedV, 1)
    for j=1:size(seedW, 2)
      seedColA = seedV(i, :).';
      seedColB = seedW(:, j);

      [d2args{1:nActArgs}] = createHessians(1, funcArgs{independents});
      [dargsA{1:nActArgs}] = createSeededGradientsFor(seedColA, funcArgs{independents});
      [dargsB{1:nActArgs}] = createSeededGradientsFor(seedColB, funcArgs{independents});

      dfargs = admMergeArgs2(d2args, dargsA, dargsB, funcArgs, independents);

      [output{1:nDFResults}] = diffFunction(dfargs{:});
      
      if isempty(Jacobian)
        varargout = output(nactOutIndices);
        nCompOut = admTotalNumel(output{hessIndices+3});
        Jacobian = zeros(nCompOut, size(seedW, 2));
        Hessian = zeros(size(seedV, 1), size(seedW, 2), nCompOut);
      end

      if j == 1
        jcol = admJacFor(output{jacIndices});
        Jacobian(:, i) = jcol;
      end
      
      hessSlice = admHessianFor(output{hessIndices});
      Hessian(i,j,:) = hessSlice;
      
    end
  end

