% function [Jacobian, varargout] = admDiffFD(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Compute first order derivatives of function given by handle,
%  evaluated at the arguments arg1, arg2, ..., argN. This works by
%  running the finite difference method on each component of input
%  arguments.
%
%  The derivatives are returned in the form of a so called Jacobian
%  matrix, which contains the derivatives of each result parameter of
%  the function given by handle, w.r.t. to all of the function
%  parameters.
%
%  When seedMatrix is equal to 1, then the full Jacobian is computed
%  and returned. Otherwise the matrix product
%
%       Jacobian * seedMatrix 
%
%  is computed and returned, but WITHOUT actually computing the full
%  jacobian matrix. Setting seedMatrix equal to 1 is an abbreviation
%  for using eye(K), where K is the total number of components in the
%  function arguments. Giving a column vector of length K as
%  seedMatrix is an efficient way of computing matrix-vector products
%  with the Jacobian.
%
%  The arguments following seedMatrix are the function arguments. The
%  derivative of the function given by handle is evaluated at these
%  arguments. Each component is distorted by a small quantity in turn
%  to evaluate the finite difference approximation of the function
%  w.r.t. that component.
%
%  When the last argument is a struct with a field named admopts, this
%  argument is used by this function to obtain certain
%  parameters. Specifically, with the fields dependents and
%  independents a subset of the in- and output parameters can be
%  selected. The field fdMode can be set to either 'forward',
%  'backward', or 'central', which selects forward, backward or
%  central finite difference approximations resp. The field fdStep
%  controls the step size h.
%
%  For this method to work, there must be no poles or discontinuities
%  near the point of evaluation. The precision of the derivatives
%  computed with this function depends on the proper setting of the
%  fdStep option. The precision can at most be half of the machine
%  precision. The runtime depends linearly on the number of columns of
%  the seedMatrix. The functions admDiffFor, admDiffVFor, and
%  admDiffComplex usually yields fully precise results and are thus a
%  better alternative. In order to compute products with the
%  transposed Jacobian, use the function admDiffRev.
%
% see also admDiffFor, admDiffVFor, admDiffRev, admDiffComplex,
% admOptions.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiffFD(handle, seedMatrix, varargin)
  
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
    if admOpts.checkoptions
      admCheckOptions(admOpts);
    end
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end

  if isempty(admOpts.nargout)
    functionName = func2str(handle);
    if functionName(1) == '@'
      fNargout = 1;
    else
      try
        fNargout = nargout(functionName);
      catch
        fNargout = 1;
      end
    end
    if fNargout < 0
      fNargout = 1;
      warning('adimat:admDiffFD:cannotGetNargout', ['Could not ' ...
                          'determine nargout of the function ' ...
                          '%s,\npresumably because it has a variable number of ' ...
                          'output arguments (varargout).\nAssuming nargout(%s) ' ...
                          '= 1,\notherwise you can use nargout option ' ...
                          'field to specify the correct value.'], functionName, functionName);
    end
  else
    fNargout = admOpts.nargout;
  end

  nFuncArgs = length(funcArgs);
  independents = admOpts.independents;
  if isempty(independents)
    independents = 1:nFuncArgs;
  end
  nActArgs = length(independents);

  dependents = admOpts.dependents;
  if isempty(dependents)
    dependents = 1:fNargout;
  end

  nCompInputs = admTotalNumel(funcArgs{independents});

  seedW = seedMatrix;
  if ~isnumeric(seedW)
    seedW = 1;
  end
  [seedMatrix coloring jPattern] = admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts);

  fdMode = admCanonFDMethodName(admOpts.fdMode);

  if isstruct(admOpts.fdAccuracyOrder)
    accOrder = admOpts.fdAccuracyOrder.(fdMode);
  else
    accOrder = admOpts.fdAccuracyOrder;
  end
  
  vectorize = [];
  if isfield(admOpts, 'x_vectorize') 
    vectorize = admOpts.x_vectorize;
  end
  
  for doi=1:length(admOpts.derivOrder)
    derivOrder = admOpts.derivOrder(doi);
    
    coeffs = admFDCoeffs(fdMode, derivOrder, accOrder);

    if isempty(admOpts.fdStep)
      ch = eps.^(1/(2 .^ derivOrder));
    else
      if length(admOpts.fdStep) >= derivOrder
        ch = admOpts.fdStep(derivOrder);
      else
        ch = admOpts.fdStep(end);
      end
    end
    
    switch fdMode
     case 'central'
      [TCs, varargout{1:fNargout}] = ...
          admComputeDerivCentralDD(handle, seedMatrix, independents, ...
                                   dependents, fNargout, ch, ...
                                   admOpts.functionEvaluation, coeffs, derivOrder, ...
                                   admOpts.fdContractSteps, vectorize, funcArgs{:});
     case 'backward'
      [TCs, varargout{1:fNargout}] = ...
          admComputeDerivDD(handle, seedMatrix, independents, ...
                            dependents, fNargout, -ch, coeffs, derivOrder, ...
                            admOpts.fdContractSteps, funcArgs{:});
     case 'forward'
      [TCs, varargout{1:fNargout}] = ...
          admComputeDerivDD(handle, seedMatrix, independents, ...
                            dependents, fNargout, ch, coeffs, derivOrder, ...
                            admOpts.fdContractSteps, funcArgs{:});
     otherwise
      error('adimat:admDiffFD:internalError', ...
            'Mode switch ''%s'' for FD mode is not supported', fdMode)
    end
  
    if ~isempty(jPattern)
      TCs = admUncompressJac(TCs, jPattern, coloring, seedW);
    end

    if length(admOpts.derivOrder) == 1
      Jacobian = TCs ./ prod(1:derivOrder);
    else
      if doi == 1
        Jacobian = zeros([size(TCs) length(admOpts.derivOrder)]);
      end
      Jacobian(:,:,doi) = TCs ./ prod(1:derivOrder);
    end
  end
  
% $Id: admDiffFD.m 5100 2016-05-19 09:04:31Z willkomm $
