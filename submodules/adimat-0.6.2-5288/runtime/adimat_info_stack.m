% function r = adimat_info_stack(name)
%   get/set name of ADiMat's stack implementation.
%   This functionality is implemented by modifying the path() such
%   that different versions of the function adimat_store are used.
%
% adimat_info_stack('avail')
% adimat_info_stack('list')
% adimat_info_stack('?')
%   - return list of available stack implementations
%
% adimat_info_stack('log')
%
% adimat_info_stack('check')
%
% adimat_info_stack('save')
%
% adimat_info_stack('null')
%
% adimat_info_stack(path)
%   - this simply calls addpath(path)
%
% adimat_info_stack()
%   - this returns the argument last successfully used with adimat_info_stack
%
% Not all stack implementations exist or are useable on all machines
% or interpreters. The implementations whose name begins with matlab
% only work in MATLAB, those who start with octave only with GNU
% octave.
%
% see also adimat_store, adimat_push, adimat_adjoint
%
% This file is part of the ADiMat runtime environment
%
function r = adimat_info_stack(name)
  adimathome = adimat_home;
  if ispc
    adimat_prefix = adimathome;
  else
    adimat_prefix = [ adimathome '/share/adimat'];
  end
  stackNames = { ...
      'log',
      'check',
      'save',
      'null'
               };
  for i=1:length(stackNames)
    availNames = {};
    for i=1:length(stackNames)
      newPath = [adimat_prefix '/info-stacks/' stackNames{i}];
      if (~isempty(strfind(computer, '-')) && ...
          isempty(strfind(stackNames{i}, 'matlab'))) || ...
            (isempty(strfind(computer, '-')) && ...
             isempty(strfind(stackNames{i}, 'octave')))
        if isdir(newPath)
          availNames{end + 1} = stackNames{i};
        end
      end
    end
    availNames = availNames';
    stackNames = availNames;
  end
  for i=1:length(stackNames)
    stackPathes{i} = [adimat_prefix '/info-stacks/' stackNames{i}];
  end
  r = true();
  if nargin > 0
    switch name
     case {'avail', 'list', '?'}
      r = availNames;
     case availNames
      newPath = [adimat_prefix '/info-stacks/' name];
      if ~isdir(newPath)
        warning('adimat:runtime:stack:adimat_info_stack', ['The path "%s" ' ...
                            'does not exist, the stack named "%s" is ' ...
                            'not implemented'], newPath, name);
        r = false();
      else
        [oldPath b c] = fileparts(which('adimat_stack_info'));
        if ~isempty(oldPath)
          rmpath(oldPath);
        end
        addpath(newPath);
      end
     otherwise
      % none of the above was given, assume it is a directory to
      % add to the path
      if ~isdir(name)
        warning('adimat:runtime:stack:adimat_info_stack', ['No stack named "%s" exists and the path "%s" ' ...
                            'is not a valid directory'], name, name);
        r = false();
      else
        cleanedPath = removePaths(stackPathes);
        path([name ':' cleanedPath]);
      end
    end
  else
    r = getDirectoryOfMFile(which('adimat_stack_info'));
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
  pcomps = splitString(path, ':');
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
% $Id: adimat_info_stack.m 3218 2012-03-13 22:04:08Z willkomm $
