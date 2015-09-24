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
  
  for i=fliplr(1:nFHs)
    argfi = admOpts.functionHandles(i);
    argfh = funcArgs{argfi};
    fhName = func2str(argfh);
    rec_fh = str2func(['rec_' fhName]);
    ret_fh = str2func(['ret_' fhName]);
    funcArgs = {funcArgs{1:argfi} rec_fh ret_fh funcArgs{argfi+1:end}};
  end
  
  if isequal(seedMatrix, 1)
    [dargs{1:nActResults}] = createFullGradients(functionResults{dependents});
  else
    [dargs{1:nActResults}] = createSeededGradientsRev(full(seedMatrix), functionResults{dependents});
  end
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

  Jacobian = admJacRev(output{1:nActArgs});
  varargout = output(nActArgs+1:nDFResults);
