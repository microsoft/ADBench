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
% Copyright 2009-2013 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University, TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [result, varargout] = ...
      admComputeDerivFor(diffFunction, seedMatrix, ...
                         independents, dependents, ...
                         fNargout, admOpts, varargin)
  
  funcArgs = varargin;
  
  secondorderfwd = any(find(admOpts.derivOrder == 2));
  
  nActArgs = length(independents);
  nActResults = length(dependents);

  nDFResults = fNargout + nActResults;
  if secondorderfwd
    nDFResults = nDFResults + nActResults.*2;
  end

  actOutIndices = admDerivIndices(dependents);
  jacIndices = actOutIndices;
  if secondorderfwd
    hessIndices = actOutIndices + (0:2:2.*length(actOutIndices)-2);
    jacIndices = hessIndices + 1;
    allJacIndices = [hessIndices + 1 hessIndices + 2];
    actOutIndices = union(hessIndices, allJacIndices);
    nactOutIndices = admNDerivIndices2(fNargout, dependents);
  else
    nactOutIndices = admNDerivIndices(fNargout, dependents);
  end

  totNumEl = admTotalNumel(varargin{independents});
  if ~isequal(seedMatrix, 1)
    ndd = size(seedMatrix, 2);
    if totNumEl ~= size(seedMatrix, 1)
      error('adimat:for:seedMatrixNotConforming', ...
            ['In Forward Mode (FM), the number of rows of the seed ' ...
             'matrix S must be identical with the total number of ' ...
             'components in the (active) function arguments. However, ' ...
             'admTotalNumel(independents) == %d and size(S, 1) ' ...
             '= %d'], totNumEl, size(seedMatrix, 1));
    end
  else
    ndd = totNumEl;
  end
  
  Jacobian = [];
  T2Coeffs = [];
  colJ = 1;

  for i=1:ndd
    if isequal(seedMatrix, 1)
      seedCol = zeros(totNumEl, 1);
      seedCol(i) = 1;
    else
      seedCol = seedMatrix(:, i);
    end
    
    if ~secondorderfwd
      [dargs{1:nActArgs}] = createSeededGradientsFor(seedCol, funcArgs{independents});
      dfargs = admMergeArgs(dargs, funcArgs, independents);
    else
      [d2args{1:nActArgs}] = createHessians(1, funcArgs{independents});
      [dargs{1:nActArgs}] = createSeededGradientsFor(seedCol, funcArgs{independents});
      dfargs = admMergeArgs2(d2args, dargs, dargs, funcArgs, independents);
    end

    [output{1:nDFResults}] = diffFunction(dfargs{:});

    if admOpts.checkResultSizes > 0
      admCheckResultSizes(output(actOutIndices + 1), output(actOutIndices));
    end
    
    if isempty(Jacobian)
      varargout = output(nactOutIndices);
      Jacobian = zeros(admTotalNumel(output{jacIndices}), size(seedMatrix, 2));
      if secondorderfwd
        T2Coeffs = Jacobian;
      end
    end

    jcol = admJacFor(output{jacIndices});
    Jacobian(:, colJ) = jcol;
    if secondorderfwd
      hessCol = admTaylor2For(output{hessIndices});
      T2Coeffs(:,colJ) = hessCol;
    end

    colJ = colJ + 1;
  end

  if ndd == 0
    seedCol = zeros(0, 1);
    if ~secondorderfwd
      [dargs{1:nActArgs}] = createSeededGradientsFor(seedCol, funcArgs{independents});
      dfargs = admMergeArgs(dargs, funcArgs, independents);
    else
      [d2args{1:nActArgs}] = createHessians(1, funcArgs{independents});
      [dargs{1:nActArgs}] = createSeededGradientsFor(seedCol, funcArgs{independents});
      dfargs = admMergeArgs2(d2args, dargs, funcArgs, independents);
    end
    [output{1:nDFResults}] = diffFunction(dfargs{:});
    varargout = output(nactOutIndices);
  end

  if length(admOpts.derivOrder) == 1
    if admOpts.derivOrder == 1
      result = Jacobian;
    else
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
