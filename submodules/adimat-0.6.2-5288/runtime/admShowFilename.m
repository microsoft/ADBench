% function res = admShowFilename(fname)
%
%  Remove current directory prefix from filename.
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment.
%
function res = admShowFilename(fname)
  cwd = pwd();
  n = length(cwd);
  if strncmp(cwd, fname, n)
    res = ['.' fname(n+1:end)];
  else
    res = fname;
  end

% $Id: admShowFilename.m 3020 2011-08-26 08:31:03Z willkomm $
