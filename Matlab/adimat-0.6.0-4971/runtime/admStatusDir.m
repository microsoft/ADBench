% function statusDirName = admStatusDir(functionFile)
%
% Return the name of the ADiMat status directory for function
% functionFile, which must be a full path. In the status directory
% ADiMat save information regarding the differentiated functions in
% the directory, such as the dependency list and the last options used.
%
% see also admDepList, admLastOption
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010,2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function statusDirName = admStatusDir(functionFile)
  [dir, file, stem] = fileparts(functionFile);
  adimatDirName = '.adimat';
  if ~isempty(dir)
    statusDirName = [dir '/' adimatDirName];
  else
    statusDirName = adimatDirName;
  end
  if ~exist(statusDirName, 'dir')
    fprintf(admLogFile, 'Creating ADiMat status directory %s\n', statusDirName);
    if ~isempty(dir)
      s = mkdir(dir, adimatDirName);
    else
      s = mkdir(adimatDirName);
    end
  end
  if strncmp('g_', file, 2)
    file = file(3:end);
  elseif strncmp('a_', file, 2)
    file = file(3:end);
  elseif strncmp('d_', file, 2)
    file = file(3:end);
  end
  depList = [statusDirName '/' file '.admdeps'];
% $Id: admStatusDir.m 2967 2011-06-09 14:52:33Z willkomm $
