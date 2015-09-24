% function [Jacobian, varargout] = ...
%      admComputeDerivFor(diffFunction, seedMatrix, ...
%                         independents, dependents, fNargout, ...
%                         admOpts, varargin)
%
% see also admDiffRev, admDiffVFor, admTransform, createFullGradients,
% createSeededGradients, admJacFor, admOptions, adimat_derivclass.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2009-2013 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University, TU Darmstadt
% Copyright (C) 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [result, varargout] = admComputeDerivFor(diffFunction, ...
                                                    seedMatrix, ...
                                                    independents, ...
                                                    dependents, ...
                                                    fNargout, ...
                                                    admOpts, ...
                                                    varargin)
  
  
  funcArgs = varargin;
  
  nActArgs = length(independents);
  nActResults = length(dependents);

  secondorderfwd = any(find(admOpts.derivOrder == 2));

  nDFResults = fNargout + nActResults;
  if secondorderfwd
    nDFResults = nDFResults + nActResults.*2;
  end

  actOutIndices = admDerivIndices(dependents);
  jacIndices = actOutIndices;
  if secondorderfwd
    actOutIndices = admDerivIndices(dependents);
    hessIndices = actOutIndices + (0:2:2.*length(actOutIndices)-2);
    jacIndices = hessIndices + 1;
    allJacIndices = [hessIndices + 1 hessIndices + 2];
    actOutIndices = union(hessIndices, allJacIndices);
  end
  nactOutIndices = setdiff(1:nDFResults, actOutIndices);

  nCompInputs = admTotalNumel(varargin{independents});
  if isequal(seedMatrix, 1)
    ndd = nCompInputs;
  else
    if nCompInputs ~= size(seedMatrix, 1)
      error('adimat:for:seedMatrixNotConforming', ...
            ['In Forward Mode (FM), the number of rows of the seed ' ...
             'matrix S must be identical with the total number of ' ...
             'components in the (active) function arguments. However, ' ...
             'admTotalNumel(independents) == %d and size(S, 1) ' ...
             '= %d'], nCompInputs, size(seedMatrix, 1));
    end
    ndd = size(seedMatrix, 2);
  end
  
  if secondorderfwd
    [d2args{1:nActArgs}] = createHessians(ndd, funcArgs{independents});
  end
  if isequal(seedMatrix, 1)
    [dargs{1:nActArgs}] = createFullGradients(funcArgs{independents});
  else
    [dargs{1:nActArgs}] = createSeededGradientsFor(seedMatrix, funcArgs{independents});
  end
  if ~secondorderfwd
    dfargs = admMergeArgs(dargs, funcArgs, independents);
  else
    dfargs = admMergeArgs2(d2args, dargs, dargs, funcArgs, independents);
  end
 
  [output{1:nDFResults}] = diffFunction(dfargs{:});

  if admOpts.checkResultSizes > 0
    admCheckResultSizes(output(actOutIndices + 1), output(actOutIndices));
  end
  
  varargout = output(nactOutIndices);
  Jacobian = admJacFor(output{jacIndices});
  if secondorderfwd
    T2Coeffs = admTaylor2For(output{hessIndices});
  end
  
  if length(admOpts.derivOrder) == 1
    if admOpts.derivOrder == 1
      result = Jacobian;
    else % must be == 2
      result = T2Coeffs .* 0.5;
    end
  else
    result = zeros([size(Jacobian) length(admOpts.derivOrder)]);
    for i=1:length(admOpts.derivOrder)
      doi = admOpts.derivOrder(i);
      switch doi
       case 1, result(:,:,i) = Jacobian;
       case 2, result(:,:,i) = T2Coeffs .* 0.5;
      end
    end
  end
% $Id: admComputeDerivFor.m 4582 2014-06-20 21:09:56Z willkomm $
