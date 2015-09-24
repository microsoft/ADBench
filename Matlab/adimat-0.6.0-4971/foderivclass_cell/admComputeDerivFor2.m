% function [Hessian, Jacobian, varargout] = ...
%      admComputeDerivFor2(diffFunction, seedV, seedW, ...
%                         independents, dependents, fNargout, varargin)
%
% Compute derivatives in second order FM with RE opt_derivclass or
% opt_sp_derivclass.
%
% see also admDiffFor2, admOptions, adimat_derivclass.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
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

  [d2args{1:nActArgs}] = createHessians([size(seedV, 1) size(seedW, 2)], funcArgs{independents});
  [dargsV{1:nActArgs}] = createSeededGradientsFor(seedV.', funcArgs{independents});
  for k=1:nActArgs
    dargsV{k} = set(dargsV{k}, 'left', true);
  end
  [dargsW{1:nActArgs}] = createSeededGradientsFor(seedW, funcArgs{independents});
  dfargs = admMergeArgs2(d2args, dargsV, dargsW, funcArgs, independents);
 
  [output{1:nDFResults}] = diffFunction(dfargs{:});
 
  Jacobian = admJacFor(output{jacIndices});
  Hessian = admHessianFor(output{hessIndices});

  varargout = output(nactOutIndices);
