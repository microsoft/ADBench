% function [res vnum] = admIsOctave() 
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
%
% This file is part of the ADiMat runtime environment.
%
function [res vnum] = admIsOctave(minVersion)
  res = exist('octave_config_info', 'builtin') > 0;
  
  if res && nargin > 0
    % check for a minimum version
    v = version;
    points = strfind(v, '.');
    if length(points) > 1
      v = v(1:points(2)-1);
    end
    vnum = str2num(v);
    res = vnum >= minVersion;
  end

% $Id: admIsOctave.m 3746 2013-06-13 11:11:13Z willkomm $
