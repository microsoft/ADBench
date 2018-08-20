% function r = adimat_stack(name)
%   get/set name of ADiMat's stack implementation.
%   This functionality is implemented by modifying the path() such
%   that different versions of the function adimat_store are used.
%
% adimat_stack('avail')
% adimat_stack('list')
% adimat_stack('?')
%   - return list of available stack implementations
%
% adimat_stack('native-cell')
%   - this uses native MATLAB commands, saving the adimat_push'd
%     objects in a cell array
%
% adimat_stack('native-save')
%   - like native-cell, except that on every k-th push the stack is
%     saved to disk
%
% adimat_stack('file')
%   - serializes objects and writes them to a file on disk
%   - MATLAB only
%
% adimat_stack('sstream')
%   - serializes objects and writes them to a string buffer
%   - MATLAB only
%
% adimat_stack('abuffered-file')
%   - serializes objects and writes them to a file on disk, with
%   buffer size configurable using adimat_stack_buffer_size and
%   asynchronous writes and asynchronous prefetching reads
%   - see adimat_stack_buffer_size, adimat_aio_init
%   - MATLAB only
%
% adimat_stack('null')
%   - stack does nothing
%
% adimat_stack(path)
%   - this simply calls addpath(path)
%
% adimat_stack()
%   - this returns the argument last successfully used with adimat_stack
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
% Copyright 2009-2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
%                     RWTH Aachen University
function r = adimat_stack(in_name)
  persistent curStackName
  adimathome = adimat_home;
  if ispc
    adimat_prefix = adimathome;
  else
    adimat_prefix = [ adimathome '/share/adimat'];
  end

  stackNames = { ...
      'native-cell',
      'native-save',
      'file',
      'buffered-file',
      'abuffered-file',
      'abuffered-file-aio',
      'abuffered-file-mpio',
      'abuffered-file2',
      'sstream',
      'mem',
      'native-null',
      'native-check'
               };
  availNames = {};
  for i=1:length(stackNames)
    sn = stackNames{i};
    newPath = [adimat_prefix '/stacks/' sn];
    if isdir(newPath)
      availNames{end + 1} = sn;
    else
      if admIsOctave()
        sn = ['octave-' sn];
      else
        sn = ['matlab-' sn];
      end
      newPath = [adimat_prefix '/stacks/' sn];
      if isdir(newPath)
        availNames{end + 1} = sn;
      end
    end
  end
  availNames = availNames';
  stackNames = availNames;
  for i=1:length(stackNames)
    stackPathes{i} = [adimat_prefix '/stacks/' availNames{i}];
  end
  r = true();
  if nargin > 0
    switch in_name
     case {'avail', 'list', '?'}
      r = availNames;
     otherwise
      if ~startswith(in_name, 'matlab-') ...
            && ~startswith(in_name, 'octave-') ...
            && ~startswith(in_name, 'native-')
        if admIsOctave()
          prefix = 'octave-';
        else
          prefix = 'matlab-';
        end
        name = [prefix in_name];
      else
        name = in_name;
      end
  
      switch name
       case availNames
        newPath = [adimat_prefix '/stacks/' name];
        if ~isdir(newPath)
          warning('adimat:runtime:stack:adimat_stack', ['The path "%s" ' ...
                              'does not exist, the stack named "%s" is ' ...
                              'not implemented'], newPath, name);
          r = false();
        else
          [oldPath b c] = fileparts(which('adimat_store'));
          if ~isempty(oldPath)
            rmpath(oldPath);
          end
          addpath(newPath);
          curStackName = in_name;
        end
       otherwise
        % none of the above was given, assume it is a directory to
        % add to the path
        if ~isdir(name)
          warning('adimat:runtime:stack:adimat_stack', ['No stack named "%s" exists and the path "%s" ' ...
                              'is not a valid directory'], name, name);
          r = false();
        else
          cleanedPath = removePaths(stackPathes);
          path([name ':' cleanedPath]);
        end
      end
    end
  else
    if isempty(curStackName)
      curStackName = getDirectoryOfMFile(which('adimat_store'));
    end
    r = curStackName;
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
function z = startswith(str, pat)
  z = strncmp(str, pat, length(pat));
end
% $Id: adimat_stack.m 4525 2014-06-13 21:25:19Z willkomm $
