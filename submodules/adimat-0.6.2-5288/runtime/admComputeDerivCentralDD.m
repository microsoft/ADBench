% function [Jacobian, varargout] = ...
%      admComputeDerivCentralDD(diffFunction, seedMatrix, ...
%                         independents, dependents, fNargout, varargin)
%
% see also admDiffFD.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2014, 2016 Johannes Willkomm
% Copyright (C) 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = ...
      admComputeDerivCentralDD(diffFunction, seedMatrix, independents, dependents, ...
                               fNargout, ch, functionEvaluation, ...
                               coeffs, derivOrder, fdContractSteps, ...
                               vectorize, varargin)
  
  funcArgs = varargin;
  
  nActArgs = length(independents);

  ncoeffs = length(coeffs);
  if ncoeffs == 0
    error('number of coeffecients is zero');
  end
  if mod(ncoeffs, 2) ~= 1
    error('number of coeffs must be uneven');
  end
  
  if abs(sum(coeffs)) > 1e-12
    error('coeffs must sum to zero');
  end
  
  if fdContractSteps
    % contract steps by total length of interval
    nsteps = ncoeffs - 1;
    coeffs = coeffs .* nsteps.^derivOrder;
  end

  centrali = ceil(ncoeffs/2);
  centralcoeff = coeffs(centrali);

  if functionEvaluation || centralcoeff ~= 0
    [varargout{1:fNargout}] = diffFunction(funcArgs{:});
  else
    [varargout{1:fNargout}] = deal([]);
  end

  if isequal(seedMatrix, 1)
    totNumEl = admTotalNumel(funcArgs{independents});
    seedMatrix = eye(totNumEl);
  end
  ndd = size(seedMatrix, 2);
  
  indep_numels = cellfun('prodofsize', varargin(independents));
  seedBlocks = mat2cell(seedMatrix, indep_numels, size(seedMatrix, 2));
  vFuncArgs = funcArgs;
  for k=vectorize
    if ~any(find(independents == k))
      vFuncArgs{k} = repmat(vFuncArgs{k}, [1 ndd]);
    end
  end

  for ci = 1:length(coeffs)
    
    hsteps = (ci - centrali);

    if hsteps == 0
      if centralcoeff ~= 0
        % it's the central coefficient, i.e. the function result
        Jacobian = bsxfun(@plus, Jacobian, centralcoeff .* admGetV(varargout(dependents)));
        % else: coeff is zero, no contribution
      end
      continue;
    end

    for k=1:length(independents)
      inputBlocks{k} = bsxfun(@plus, funcArgs{independents(k)}(:), (hsteps .* ch) .* seedBlocks{k});
    end

    Jblock = cell(1, fNargout);
    
    if vectorize
      vFuncArgs(independents) = inputBlocks;
      [outputs{1:fNargout}] = diffFunction(vFuncArgs{:});
      Jblock(dependents) = outputs;
    else
      inputsC = inputMatrix2CellOfArguments(inputBlocks, funcArgs, independents);
      
      [outputs{1:fNargout}] = cellfun(diffFunction, inputsC{:}, 'uniformoutput', false);
    
      for k=dependents
        outk = outputs{k};
        if length(outk) > 0
          outk{1} = outk{1}(:);
          szk = [numel(outk{1}) 1];
          for i=2:length(outk)
            outk{i} = reshape(outk{i}, szk);
          end
        end
        Jblock{k} = horzcat(outk{:});
      end

    end

    if ci == 1
      Jacobian = coeffs(ci) .* vertcat(Jblock{:});
    else
      Jacobian = Jacobian + coeffs(ci) .* vertcat(Jblock{:});
    end
    
  end

  Jacobian = Jacobian ./ (ch.^derivOrder);
  
% $Id: admComputeDerivCentralDD.m 5102 2016-05-29 20:50:19Z willkomm $
