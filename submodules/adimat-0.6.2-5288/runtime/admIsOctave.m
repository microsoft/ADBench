% function [res vnum] = admIsOctave() 
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
% Copyright 2017 Johannes Willkomm
%
% This file is part of the ADiMat runtime environment.
%
function [res vnum] = admIsOctave(minVersion)
  res = exist('octave_config_info') > 0;
  
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

