% function res = admLogLevel(lev)
%
% Set ADiMat logging level, which controls which ADiMat messages are
% printed. The function returns the current level. With one arg, set
% the new level.
%
% Copyright 2010,2011 Johannes Willkomm, Scientific Computing Group
%                     TU Darmstadt
function res = admLogLevel(lev)
  persistent level
  if isempty(level)
    level = 2; % the default log level
  end
  if nargin > 0
    level = lev;
  end
  res = level;
% $Id: admLogLevel.m 3112 2011-11-07 17:46:12Z willkomm $
