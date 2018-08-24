% function r = adimat_derivclass(name)
%   get/set name of ADiMat's derivative class implementation.
%   This functionality is implemented by modifying the path() such
%   that different versions of the function adimat_store are used.
%
%   Since version 3.6, Octave does also support classes, so these can
%   now also be used there, enabling vector mode. Exceptions are the
%   two classes that are written with the newer classdef syntax.
%
% adimat_derivclass('avail')
% adimat_derivclass('list')
% adimat_derivclass('?')
%   - return list of available derivative class implementations
%
% adimat_derivclass('foderivclass')
%   - currently the fastest derivative container class, but possibly
%   lacking some features. Implemented using classdef syntax, hence
%   does not work with Octave.
%
% adimat_derivclass('opt_derivclass')
%   - the most well tested and complete derivative container class,
%   though somewhat slow
%
% adimat_derivclass('foderivclass_cell')
%   - similar to the above, but implemented with classdef syntax, hence
%   does not work with Octave.
%
% adimat_derivclass('opt_sp_derivclass')
%   - optimized MATLAB sparse derivative class
%
% adimat_derivclass('mat_derivclass')
%   - derivative class using platform independent MATLAB code
%
% adimat_derivclass('mex_derivclass')
%   - derivative class with mex function implemented in C/C++
%     this may not be available on your platform
%
% adimat_derivclass('scalar_directderivs')
%   - Use this for using native doubles as derivatives. This is not
%     actually a derivative class, it just provides the functions
%     g_zeros, createFullGradients, etc. which are present in the
%     generated code or needed by code calling the AD code. Note you
%     can only use code generated with --noloopsaving, as this
%     derivative implementation lacks the ls_* functions.
%
% adimat_derivclass(path)
%   - this simply calls addpath(path)
%
% adimat_derivclass()
%   - this returns the argument last successfully used with adimat_derivclass
%
% Not all derivative class implementations exist or are useable on all
% machines or interpreters. The class based implementations only work
% in MATLAB, with GNU Octave you can only use scalar_directderivs.
%
% see also g_zeros, createFullGradients, ls_mprod, adimat_adjoint
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2018 Johannes Willkomm
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
% Copyright 2003-2008 Andre Vehreschild, Institute for Scientific Computing
%           RWTH Aachen University.
function r = adimat_derivclass(name)
  persistent derClassName
  if nargin > 0
    adimathome = adimat_home;
    if ispc
      adimat_prefix = adimathome;
    else
      adimat_prefix = [ adimathome '/share/adimat'];
    end
    stackNames = { ...
        'mat_derivclass'
        'mat_derivclass2'
        'mex_derivclass'
        'opt_derivclass'
        'opt_sp_derivclass'
        'arrderivclass'
        'arrderivclassvxdd'
        'arrderivclassdef'
        'foderivclass_cell'
        'scalar_directderivs'
        'vector_directderivs'
        'tvector_directderivs'
                 };
    for i=1:length(stackNames)
      stackPathes{i} = [adimat_prefix '/' stackNames{i}];
    end
    stackName = name;
    switch name
     case {'avail', 'list', '?'}
      r = {};
      for i=1:length(stackNames)
        newPath = [adimat_prefix '/' stackNames{i}];
        if isdir(newPath)
          r = { r{:}, stackNames{i} };
        end
      end
      r = r';
     case stackNames
      newPath = [adimat_prefix '/' name];
      if ~isdir(newPath)
        warning('adimat:runtime:derivclass:adimat_derivclass', ['The path %s ' ...
                            'does not exist, the derivative class named %s is ' ...
                            'not implemented'], newPath, name);
        r = false();
      else
        oldFile = which('g_zeros');
        if isempty(oldFile)
          oldFile = which('d_zeros');
          if isempty(oldFile)
            oldFile = which('t_zeros');
          end
        end
        [oldPath b c] = fileparts(oldFile);
        if ~isempty(oldPath)
          rmpath(oldPath);
        end
        addpath(newPath);
      end
     otherwise
      % none of the above was given, assume it is a directory to
      % add to the path
      cleanedPath = removePaths(stackPathes);
      path([name ':' cleanedPath]);
    end
    derClassName = name;
  else
    if isempty(derClassName)
      derClassName = getDirectoryOfMFile(which('g_dummy'));
    end
  end
  if nargout > 0 || nargin == 0
    r = derClassName;
  end
end

function name = getDirectoryOfMFile(path)
  if ~isempty(path)
    [a b c] = fileparts(path);
    [a b c] = fileparts(a);
    name = b;
  else
    name = [];
  end
end

function list = splitString(str, pat)
  pStarts = regexp(str, pat, 'start');
  list = cell(1, length(pStarts));
  offs = 1;
  for i=1:length(pStarts)
    list{i} = str(offs:pStarts(i)-1);
    offs = pStarts(i) + 1;
  end
end

function newpath = removePaths(plist)
  curpath = path();
  pcomps = splitString(path(), ':');
  newpath = '';
  for i=1:length(pcomps)
    pdir = pcomps{i};
    where = strfind(plist, pdir);
    if all(cellfun('isempty', where))
      if isempty(newpath)
        newpath = pdir;
      else
        newpath = [newpath ':' pdir];
      end
    end
  end
end
