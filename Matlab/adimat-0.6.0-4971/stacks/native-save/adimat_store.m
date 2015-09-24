% function r = adimat_store(mode, v)
%   mode=0: pop value from stack
%   mode=1: store value on stack
%   mode=2: clear stack
%   mode=3: query stack size
%   mode=4: query reserved stack size
%   mode=5: flush the stack (N/A)
%   mode=6: return the file size of the stack (N/A)
%   mode=7: return the entire stack
%   mode=8: get/set the parameter k (default is 1000)
%
% This implementation uses a native cell array, which is save out to
% disk whenever its size reaches k items. 
%
% To set the parameter k to 10, use
%
% adimat_store(8, 10)
% 
% To clear the persistent variables in this function, clear this
% function:
%
% clear adimat_store
%
% But note this will not delete the save files. To delete them,
% call adimat_store with the clear command:
%
% adimat_store(2)
% 
% see also adimat_push, adimat_pop, adimat_clear_stack,
% adimat_stack_size, adimat_stack
%
% This file is part of the ADiMat runtime environment
%
% Copyright (C) 2011,2012,2014 Johannes Willkomm
%
function r = adimat_store(mode, v)
  persistent theStack
  persistent stack_size
  persistent save_every
  persistent saveDir
  persistent saveFiles
  switch mode
   case 0
    % pop
    if stack_size == 0
      error('adimat:runtime:stack:underrun', 'adimat: error: %s', 'stack underun');
    end
    if mod(stack_size, save_every) == 0 && stack_size > 0
      sfname = saveFiles{end};
      fprintf(admLogFile('stackInfo'), 'Load stack save file %s\n', sfname);
      s = load(sfname);
      fprintf(admLogFile('stackInfo'), 'Delete stack save file %s\n', sfname);
      delete(sfname);
      saveFiles(end) = [];
      theStack = s.theStack;
    end
    r = theStack{mod(stack_size-1, save_every)+1};
    theStack{mod(stack_size-1, save_every)+1} = [];
    stack_size = stack_size - 1;
   case 1
    % push
    if length(theStack)
      stack_size = stack_size + 1;
      theStack{mod(stack_size-1, save_every)+1} = v;
      if mod(stack_size, save_every) == 0 && stack_size > 0
        sfname = mkSaveName(saveDir, floor(stack_size ./ save_every));
        fprintf(admLogFile('stackInfo'), 'Create stack save file %s\n', sfname);
        save('-v7', sfname, 'theStack');
        saveFiles{end + 1} = sfname;
        theStack = cell(save_every, 1);
      end
    else
      saveDir = mkSaveDir();
      theStack = cell(save_every, 1);
      theStack{1} = v;
      stack_size = 1;
      if isempty(save_every)
        save_every = 1000;
      end
    end
    r = stack_size;
   case 2
    % clear
    r = stack_size;
    theStack = {};
    stack_size = 0;
    deleteSaveFiles(saveFiles);
    saveFiles = {};
   case 3
    % size
    if isempty(stack_size), stack_size = 0; end
    r = stack_size;
   case 4
    % byte size: unknown
    r = 0;
   case 5
    % flush
    r = 0;
   case 6
    % file size: 0
    r = 0;
   case 7
    % return stack
    if isempty(theStack)
       r = { };
    else
       r = { theStack{1:stack_size} };
    end
   case 8
    % get/set save_every
    r = save_every;
    if nargin > 1
      save_every = v;
      deleteSaveFiles(saveFiles);
      saveFiles = {};
      theStack = cell(save_every, 1);
      stack_size = 0;
    end
   otherwise
    error('adimat:runtime:adimat_store', 'unknown mode: %d', mode);
  end
end
function savedir = mkSaveDir()
  savefile = getenv('ADIMAT_STACK_FILE');
  [savedir name stem] = fileparts(savefile);
  if isempty(savedir)
    savedir = getenv('TMP');
  end
  if isempty(savedir)
    savedir = getenv('TEMP');
  end
  if isempty(savedir)
    savedir = '.';
  end
end
function sfname = mkSaveName(savedir, i)
  sfname = sprintf('adimat-stack-%d.mat', i);
  sfname = [savedir '/' sfname];
end
function deleteSaveFiles(saveFiles)
  for i=1:length(saveFiles)
    fprintf(admLogFile('stackInfo'), 'Delete stack save file %s\n', saveFiles{i});
    delete(saveFiles{i});
  end
end
% $Id: adimat_store.m 4005 2014-01-09 14:08:18Z willkomm $
