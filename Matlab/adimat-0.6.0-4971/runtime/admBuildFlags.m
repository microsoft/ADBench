% function str = admBuildFlags(s)
%
% Construct an options string from a struct. The struct is taken as a
% name=value mapping and the resulting string has a substring ' -s
% name="value"' for each entry. Names are the struct field names,
% values are converted to string using function admToString.
%
% see also admTransform, admToString
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%           TU Darmstadt.
%
function str = admBuildFlags(s)
  default = admTransformParameters();
  str = '';
  fns = fieldnames(s);
  for i=1:length(fns)
    fn = fns{i};
    if ~isfield(default, fn) || ~isequal(default.(fn), s.(fn))
      str = [ str ' -s ' admCamelToDash(fn) '="' admToString(s.(fn)) '"'];
    end
  end
% $Id: admBuildFlags.m 3435 2012-10-11 08:01:31Z willkomm $
