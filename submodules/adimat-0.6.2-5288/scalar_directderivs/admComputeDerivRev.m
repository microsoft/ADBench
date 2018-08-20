% function [Jacobian, varargout] = ...
%       admComputeDerivRev(diffFunction, seedMatrix, ...
%                          independents, dependents, ...
%                          functionResults, admOpts, varargin)
%
% see also admDiffFor, admDiffVFor, admTransform, createFullGradients,
% createSeededGradients, admJacFor, admOptions, adimat_derivclass.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2009-2013 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University, TU Darmstadt
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = ...
      admComputeDerivRev(diffFunction, seedMatrix, ...
                         independents, dependents, ...
                         functionResults, admOpts, varargin)

  funcArgs = varargin;
  
  nActResults = length(dependents);
  nFHs = length(admOpts.functionHandles);
  nActArgs = length(independents) - nFHs;
  
  fNargout = length(functionResults);

  nDFResults = fNargout + nActArgs;
  
%  actOutIndices = admAdjointIndices(independents);
%  nactOutIndices = setdiff(1:nDFResults, actOutIndices);

  numelIn = admTotalNumel(varargin{independents});
  numelOut = admTotalNumel(functionResults{dependents});
  
  for i=fliplr(1:nFHs)
    argfi = admOpts.functionHandles(i);
    argfh = funcArgs{argfi};
    fhName = func2str(argfh);
    rec_fh = str2func(['rec_' fhName]);
    ret_fh = str2func(['ret_' fhName]);
    funcArgs = {funcArgs{1:argfi} rec_fh ret_fh funcArgs{argfi+1:end}};
  end
  
  if ~isequal(seedMatrix, 1)
    ndd = size(seedMatrix, 1);
    if numelOut ~= size(seedMatrix, 2)
      error('adimat:rev:seedMatrixNotConforming', ...
            ['In Reverse Mode (RM), the number of columns of the seed ' ...
             'matrix S must be identical with the total number of ' ...
             'components in the (active) function outputs. However, ' ...
             'admTotalNumel(dependents) == %d and size(S, 1) ' ...
             '= %d'], numelOut, size(seedMatrix, 2));
    end
  else
    ndd = numelOut;
  end

  Jacobian = zeros(ndd, numelIn);
  rowJ = 1;
  for i=1:ndd
    if isequal(seedMatrix, 1)
      seedRow = zeros(1, numelOut);
      seedRow(i) = 1;
    else
      seedRow = seedMatrix(i, :);
    end

    [dargs{1:nActResults}] = createSeededGradientsRev(seedRow, functionResults{dependents});
  
    dfargs = {funcArgs{:}, dargs{admAdjointIndices(dependents)}};
  
    [output{1:nDFResults}] = diffFunction(dfargs{:});
  
    if admOpts.checkResultSizes > 0
      if ~isempty(admOpts.functionHandles)
        actInputs = setdiff(independents, admOpts.functionHandles);
      else
        actInputs = independents;
      end
      admCheckResultSizes(funcArgs(actInputs), output(1:nActArgs));
    end

    dResults = {output{1:nActArgs}};
    if isempty(Jacobian)
      varargout = output(nActArgs+1:nDFResults);
      Jacobian = zeros(size(seedMatrix, 1), numelIn);
    end
    Jacobian(rowJ, :) = admJacRev(dResults{:});
    rowJ = rowJ + 1;
  end

  if ndd == 0
    [dargs{1:nActResults}] = createSeededGradientsRev(zeros(1, 0), functionResults{dependents});
    dfargs = {funcArgs{:}, dargs{admAdjointIndices(dependents)}};
    [output{1:nDFResults}] = diffFunction(dfargs{:});
  end

  varargout = output(nActArgs+1:nDFResults);
