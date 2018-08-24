% function [success, msg]=addiff(fname, indeps, deps, flags, debug)
%
% Differentiate function fname using ADiMat. This function is
% deprecated, please use admTransform instead.
%
% see also admTransform, admDiffFor, admDiffRev
%
% This file is part of the ADiMat runtime environment
%
function [success, msg] = addiff(fname, indeps, deps, flags, debug)
  if (nargin<5), debug = []; end
  if (nargin<4), flags = ''; end
  if (nargin<3), deps=''; end
  if (nargin<2), indeps=''; end
  [success, msg] = admTransform(fname, indeps, deps, ['-F ' flags], debug);

% $Id: addiff.template 2537 2011-01-21 16:41:49Z willkomm $
