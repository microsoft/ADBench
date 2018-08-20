% function s = admToString(obj)
%
% Return a string representing obj. Floats are converted with
% sprintf('%g', obj), integers and logicals with sprintf('%d', obj).
%
% see also admTransform, admBuildFlags
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2003-2008 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
%
function s = admToString(obj)
  if isa(obj, 'double')
    s = sprintf('%g', obj);
  elseif isa(obj, 'single')
    s = sprintf('%g', obj);
  elseif isa(obj, 'int8') || isa(obj, 'uint8') ...
        || isa(obj, 'int16') || isa(obj, 'uint16') ...
        || isa(obj, 'int32') || isa(obj, 'uint32') ...
        || isa(obj, 'int64') || isa(obj, 'uint64') ...
        || isa(obj, 'logical')
    s = sprintf('%d', obj);
  else
    s = obj;
  end
% $Id: admToString.m 2424 2010-11-16 15:48:43Z willkomm $
