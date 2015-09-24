% function r = admCompareOptions(s1, s2)
%
%  Compare ADiMat options structure: if different, re-transform the
%  source. Thus this functions checks only those fields that may
%  actually influence the transformation process.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function r = admCompareOptions(s1, s2)
  notForTransform = {'jac_nzpattern', 'coloringFunction', ...
                     'coloringFunctionArgs', 'complexStep', ...
                     'derivClassName', 'fdMode', 'fdStep', ...
                     'functionEvaluation', 'functionResults', ...
                     'nargout', 'reverseModeSwitch', 'scalarModeSwitch' ...
                    };
  if ~isempty(s1) && ~isempty(fieldnames(s1))
    s1 = rmfield(s1, notForTransform);
  end
  s2 = rmfield(s2, notForTransform);
  r = isequal(s1, s2);
  
% $Id: admCompareOptions.m 2905 2011-05-16 14:20:44Z willkomm $
