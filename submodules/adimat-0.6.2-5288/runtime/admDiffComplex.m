% function [Jacobian, varargout] = admDiffComplex(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Compute first order derivatives of function given by handle,
%  evaluated at the real arguments arg1, arg2, ..., argN. This works
%  by running the complex variable method on each component of the
%  input arguments.
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
%  selected. The field complexStep controls the step size e.
%
%  For this method to work, the function must be real and
%  analytic. Derivatives computed with this function are precise up to
%  machine precision as long as the complexStep value is small
%  enough. Thus this function returns results comparable to admDiffFor
%  and admDiffVFor. The runtime depends linearly on the number of
%  columns of the seedMatrix. In order to compute products with the
%  transposed Jacobian, use the function admDiffRev.
%
% see also admDiffFor, admDiffVFor, admDiffRev, admDiffFD, admOptions.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiffComplex(handle, seedMatrix, varargin)
  
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

  if any(admOpts.derivOrder < 1) || any(admOpts.derivOrder > 1)
    error('adimat:admDiffComplex:wrongDerivOrder', ['invalid derivative ' ...
                        'order %s: must be 1'], mat2str(admOpts.derivOrder));
  end

  if isempty(admOpts.nargout)
    functionName = func2str(handle);
    if functionName(1) == '@'
      fNargout = 1;
    else
      fNargout = nargout(functionName);
    end
    if fNargout < 0
      fNargout = 1;
      warning('adimat:admDiffComplex:cannotGetNargout', ['Could not ' ...
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
  nActResults = length(dependents);

  nCompInputs = admTotalNumel(funcArgs{independents});

  seedW = seedMatrix;
  if ~isnumeric(seedW)
    seedW = 1;
  end
  [seedMatrix coloring jPattern] = admMakeSeedMatrixFor(seedMatrix, nCompInputs, admOpts);
  
  ch = admOpts.complexStep;
  
  [Jacobian varargout{1:fNargout}] = ...
      admComputeDerivComplex(handle, seedMatrix, independents, ...
                             dependents, fNargout, ch, funcArgs{:});

  if ~isempty(jPattern)
    Jacobian = admUncompressJac(Jacobian, jPattern, coloring, seedW);
  end
  
  if admOpts.functionEvaluation > 1
    % if desired, also compute function with original arguments
    [varargout{1:fNargout}] = handle(funcArgs{:});
  end

% $Id: admDiffComplex.m 4605 2014-07-07 14:17:45Z willkomm $
