% function [Jacobian, varargout] = admDiff(handle, seedMatrix, arg1, arg2, ..., argN, admOptions?)
%
%  Call either admDiffFor, admDiffRev or admDiffVFor depending on
%  options.
%
% see also admDiffFor, admDiffRev, admDiffVFor
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function [Jacobian, varargout] = admDiff(handle, seedMatrix, varargin)
  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = varargin;
  end

  if isa(handle, 'function_handle')
    functionName = func2str(handle);
  else
    functionName = handle;
  end
  
  if isempty(admOpts.nargout)
    fNargout = nargout(functionName);
  else
    fNargout = admOpts.nargout;
  end

  functionResults = admOpts.functionResults;
  
  if isempty(functionResults)
    warning('adimat:admDiff:runningOriginalFunction', ...
            ['Running the function %s to obtain the function results. ' ...
             'If you want to avoid this, provide a copy (or objects of the same sizes) in' ...
             ' field functionResults of the admOptions structure'], ...
            functionName);
    clocks.feval = datenum(clock);
    [functionResults{1:fNargout}] = handle(funcArgs{:});
    times.feval = (datenum(clock) - clocks.feval) *24*3600;
    warning('adimat:admDiff:runningOriginalFunction', ...
            'Running the function %s took %g s', ...
            functionName, times.feval);
    admOpts.functionResults = functionResults;
  end

  tnargin = admTotalNumel(funcArgs{:});
  tnargout = admTotalNumel(functionResults{:});

  diffMode = admOpts.mode;
  reverseModeSwitch = admOpts.reverseModeSwitch;
  
  if isempty(diffMode)
    if isequal(seedMatrix, 1)
      if tnargout < tnargin * reverseModeSwitch
        warning('adimat:admDiff:autoReverse', ...
                'selecting reverse mode since #out=%d < %g * #in=%d', ...
                tnargout, reverseModeSwitch, tnargin);
        diffMode = 'r';
      else
        diffMode = 'f';
      end
    else
      if size(seedMatrix, 2) == tnargout && size(seedMatrix, 2) ~= tnargin
        diffMode = 'r';
      elseif size(seedMatrix, 1) == tnargin && size(seedMatrix, 1) ~= tnargout
        diffMode = 'f';
      elseif size(seedMatrix, 2) == tnargin && ...
            size(seedMatrix, 2) ~= tnargout && ...
            size(seedMatrix, 1) < size(seedMatrix, 2)
        diffMode = 'f';
        seedMatrix = seedMatrix.';
        warning('adimat:admDiff:autoSeedTranspose', ...
                ['selecting forward mode, even though #rows of seed ' ...
                 'matrix does not fit, as #cols does (and not #cols ' ...
                 '= #out, either). Did you mean to use the transpose' ...
                 ' of the seed matrix?']);
      elseif size(seedMatrix, 1) == tnargout && ...
            size(seedMatrix, 1) ~= tnargin && ...
            size(seedMatrix, 2) < size(seedMatrix, 1)
        diffMode = 'r';
        seedMatrix = seedMatrix.';
        warning('adimat:admDiff:autoSeedTranspose', ...
                ['selecting reverse mode, even though #cols of seed ' ...
                 'matrix does not fit, as #rows does (and not #rows ' ...
                 '= #in, either). Did you mean to use the transpose' ...
                 ' of the seed matrix?']);
      else
        error('adimat:admDiff:whichMode', ...
              ['Which mode do you want? Given your function, arguments, and seed matrix, there is no obvious choice:\n'...
               'the number of output/input components: %d / %d\n' ...
               'the number of rows/columns of the seed matrix: %d / %d\n'], ...
              tnargout, tnargin, size(seedMatrix, 1), size(seedMatrix, 2));
      end
    end
  end

  switch diffMode
   case 'F'
    [Jacobian varargout{1:length(functionResults)+1}] ...
        = admDiffFor(handle, seedMatrix, funcArgs{:}, admOpts);
   case 'f'
    [Jacobian varargout{1:length(functionResults)+1}] ...
        = admDiffVFor(handle, seedMatrix, funcArgs{:}, admOpts);
   case 'r'
    [Jacobian varargout{1:length(functionResults)+1}] ...
        = admDiffRev(handle, seedMatrix, funcArgs{:}, admOpts);
   case 'c'
    [Jacobian varargout{1:length(functionResults)+1}] ...
        = admDiffComplex(handle, seedMatrix, funcArgs{:}, admOpts);
   case 'd'
    [Jacobian varargout{1:length(functionResults)+1}] ...
        = admDiffDD(handle, seedMatrix, funcArgs{:}, admOpts);
  end
  
% $Id: admDiff.m 4251 2014-05-18 20:25:07Z willkomm $
