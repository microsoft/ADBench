% function r = admClearFunctions(functionName, prefix)
%
% see also admOptions, admDiffFor, admDiffVFor, admDiffRev.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2011 Johannes Willkomm, Scientific Computing Group
%                TU Darmstadt
function r = admClearFunctions(functionName, prefix)
  r = true;
  functionFile = which(functionName);
  depList = admDepList(functionFile);
  fid = fopen(depList);
  clist = admReadFileLines(fid);
  for i=1:length(clist)
    dFunName = [prefix clist{i}];
    fprintf(admLogFile, 'Clear function %s\n', dFunName);
    clear(dFunName);
  end
  
% $Id: admClearFunctions.m 3108 2011-11-04 09:37:23Z willkomm $
