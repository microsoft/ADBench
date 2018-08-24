% function [Jacobian, varargout] = ...
%      admComputeDerivDD(diffFunction, seedMatrix, ...
%                         independents, dependents, fNargout, varargin)
%
% see also admDiffFD.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = ...
      admComputeDerivDD(diffFunction, seedMatrix, independents, ...
                        dependents, fNargout, ch, coeffs, derivOrder, ...
                        fdContractSteps, varargin)
  
  funcArgs = varargin;
  
  nActArgs = length(independents);
  nActResults = length(dependents);

  numelIn = admGetTotalNumel(varargin{independents});
  
  Jacobian = [];

  tFun = tic;
  [varargout{1:fNargout}] = diffFunction(funcArgs{:});
  varargout{fNargout+1} = toc(tFun);

  if abs(sum(coeffs)) > 1e-12
    error('adimat:admComputeDerivDD:coeffSumNonZero', ...
          'coeffs must sum to zero: %g', sum(coeffs));
  end
  
  if isequal(seedMatrix, 1)
    totNumEl = admTotalNumel(funcArgs{independents});
    seedMatrix = eye(totNumEl);
  end
  ndd = size(seedMatrix, 2);
  
  % the central coefficient, i.e. the function result
  Jacobian = coeffs(1) .* admGetV(varargout(dependents));

  indep_numels = cellfun('prodofsize', varargin(independents));
  seedBlocks = mat2cell(seedMatrix, indep_numels, size(seedMatrix, 2));
  inputBlocks = cell(1, length(independents));

  for ci = 2:length(coeffs)
    
    hsteps = ci - 1;

    for k=1:length(independents)
      inputBlocks{k} = bsxfun(@plus, admGetV(funcArgs(independents)), (hsteps .* ch) .* seedMatrix);
    end

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

    Jacobian = bsxfun(@plus, Jacobian, coeffs(ci) .* vertcat(Jblock{:}));
    
  end

  Jacobian = Jacobian ./ (ch.^derivOrder);
  
% $Id: admComputeDerivDD.m 4594 2014-06-22 08:28:27Z willkomm $
