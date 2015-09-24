% function depList = admDepList(functionFile)
%
% Return the name of the dependency list file for functionFile.  The
% dependency list file will be in a status directory .adimat relative
% to the file, which is created by this function if it does not exist.
%
% functionFile can have or not have the .m suffix. If it starts with
% one of the prefixes g_, a_, or d_, that prefix is removed.
%
% The name mapping is illustrated by these examples:
%  - admDepList('a/b/opsin.m') -> 'a/b/.adimat/opsin.admdeps'
%  - admDepList('a/b/opsin')   -> 'a/b/.adimat/opsin.admdeps'
%  - admDepList('opsin')       -> '.adimat/opsin.admdeps'
%  - admDepList('a_opsin')     -> '.adimat/opsin.admdeps'
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                 RWTH Aachen University
function depList = admDepList(functionFile)
  [dir, file, stem] = fileparts(functionFile);
  statusDirName = admStatusDir(functionFile);
  if strncmp('g_', file, 2)
    file = file(3:end);
  elseif strncmp('a_', file, 2)
    file = file(3:end);
  elseif strncmp('d_', file, 2)
    file = file(3:end);
  end
  depList = [statusDirName '/' file '.admdeps'];
% $Id: admDepList.m 3547 2013-04-04 11:45:26Z willkomm $
