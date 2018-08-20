% function r = admRemoveNonTransformOptions(s)
%
%  Remove fields from admOptions structure that do not influence
%  transformation.
%
% see also admOptions, admCompareOptions, admCheckWhetherToTransformSource
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function r = admRemoveNonTransformOptions(s)
  notForTransform = {'jac_nzpattern', 'JPattern', 'clearFunctions', ...
                     'checkoptions', ...
                     'nochecks', ...
                     'checkResultSizes', ...
                     'coloring', 'coloringFunction', ...
                     'coloringFunctionArgs', 'complexStep', ...
                     'taylorClassName', 'derivClassName', 'derivClassType', 'fdMode', 'fdStep', ...
                     'functionEvaluation', 'functionResults', ...
                     'seedRev', ...
                     'hessianStrategy', ...
                     'stack', ...
                     'nargout', 'reverseModeSwitch', 'scalarModeSwitch', ...
                     'derivOrder', ...
                     'admDiffFunction', 'dontPlot'
                    };
  fns = fieldnames(s);
  if isempty(fns)
    r = s;
    return
  end
  extElemInds = strfind(fns, 'x_');
  for i=1:length(extElemInds)
    ind = extElemInds{i};
    if ~isempty(ind) && ind(1) == 1
      notForTransform{end+1} = fns{i};
    end
  end
  try
    r = rmfield(s, notForTransform);
  catch 
    warning('adimat:admRemoveNonTransformOptions:exception', ['rmfield ' ...
                          'failed: %s'], lasterr);
    r = struct();
  end

% $Id: admRemoveNonTransformOptions.m 4699 2014-09-18 20:56:33Z willkomm $
