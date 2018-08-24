% function n = admSelectDerivClass(nDirDer, admOpts)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function [n a] = admSelectDerivClass(nDirDer, admOpts)
  if isempty(admOpts.derivClassName)
    if ~admClassSupport()
      % without classes, we can only use scalar mode (exept with
      % admDiffVFor)
      n = 'scalar_directderivs';
    elseif nDirDer <= admOpts.scalarModeSwitch
      n = 'scalar_directderivs';
    else
      if any(admOpts.derivOrder == 2) ...
            && ~isempty(admOpts.admDiffFunction) ...
            && (strcmp(func2str(admGetFunc(admOpts.admDiffFunction)), 'admDiffFor')...
                || strcmp(func2str(admGetFunc(admOpts.admDiffFunction)), 'admDiffFor2'))
        n = 'opt_derivclass';
      else
        n = admOpts.derivClassType;
        if isempty(n)
          n = 'arrderivclass';
        else
          switch n
           case 'cell'
            n = 'opt_derivclass';
           case 'array'
            n = 'arrderivclass';
          end
        end
      end
    end
  else
    n = admOpts.derivClassName;
  end
  if admOpts.autopathchange
    if ~strcmp(adimat_derivclass, n)
      adimat_derivclass(n);
    end
  end

% $Id: admSelectDerivClass.m 4607 2014-07-08 11:10:16Z willkomm $
