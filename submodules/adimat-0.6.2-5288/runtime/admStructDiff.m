% function diffStr = admStructDiff(s1,s2)
%
%  Compare two structs and return a struct with differing fields from
%  s2.
%
% see also admOptions, admCompareOptions
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
function diffStr = admStructDiff(s1,s2)

diffStr = struct();
fns = fieldnames(s2);

for i=1:length(fns)
  fns2 = fns{i};
  v2 = s2.(fns2);
  if ~isfield(s1, fns2)
    diffStr.(fns2) = v2;
  else
    v1 = s1.(fns2);
    if ~isequal(v1, v2)
      if isstruct(v1)
        diffStr.(fns2) = admStructDiff(v1, v2);
      else
        diffStr.(fns2) = v2;
      end
    end
  end
end
  
% $Id: admStructDiff.m 3255 2012-03-28 14:32:56Z willkomm $
