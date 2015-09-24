% function [success, message] = admproc(func, indeps, deps, flags, debug)
%
% Differentiate the function func using ADiMat in reverse mode. This
% function is deprecated, please use admTransform instead.
%
% see also admTransform, admDiffFor, admDiffRev
%
% This file is part of the ADiMat runtime environment
%
function [success, msg] = admproc(fname, indeps, deps, flags, debug)
  if (nargin<5), debug = []; end
  if (nargin<4), flags = ''; end
  if (nargin<3), deps=''; end
  if (nargin<2), indeps=''; end
  if isempty(strfind([' ' flags], ' -f')) && isempty(strfind([' ' flags], ' --forward')) ...
        && isempty(strfind([' ' flags], ' -T')) && isempty(strfind([' ' flags], ' --tool-chain'))
    flags = [flags ' -r'];
  end
  [success, msg] = admTransform(fname, indeps, deps, flags, debug);

% $Id: admproc.m 3074 2011-10-19 15:06:20Z willkomm $
