% function [r n] = admLogFile(name, fh)
%
%  Set or retrieve output file handle for various ADiMat log messages.
%  
%  By default, all output file handles are set to 1 (standard console
%  output). Thus, by default, all ADiMat log messages will be printed
%  on the screen. This functions provides a mechanism to selectively
%  turn the appearance of messages on and off.
% 
%  [FD NAME] = admLogFile(CLASS) retrieves the currently set output
%  file handle FD for message class CLASS. NAME is the name of the
%  file, if that is known, or 'stdout', 'stderr', or the empty string.
%
%  [FD NAME] = admLogFile(CLASS, FILE) sets current output file handle
%  for message class NAME and returns the previously set handle FD and
%  name NAME. When FILE is of class char, it will be interpreted as a
%  file name and admLogFile will attempt to open that file for
%  writing. Otherwise FILE is considered to be an integer file handle
%  (either 1, 2, or one obtained with FOPEN).
%
%  [FD NAME] = admLogFile() is a shortcut for admLogFile('main').
%
%  [FD NAME] = admLogFile(FILE) is a shortcut for admLogFile('main',
%  FILE), provided FILE is not of class CHAR.
%  
function [r n] = admLogFile(name, fh)
  persistent adimatLogFileHandle
  persistent adimatLogFileName
  persistent devNull devNullName
  if isempty(adimatLogFileHandle)
    if ispc
      devNullName = 'nul ';
    else
      devNullName = '/dev/null';
    end
    devNull = fopen(devNullName, 'w');
    adimatLogFileHandle = struct('errors', 1, ...
                                 'warnings', 1, ...
                                 'main', 1, ...
                                 'coloring', 1, ...
                                 'null', devNull, ...
                                 'progress', 1, ...
                                 'stackInfo', 1, ...
                                 'system', 1);
    fn = fieldnames(adimatLogFileHandle);
    for i=1:length(fn)
      adimatLogFileName.(fn{i}) = ...
          fopen(adimatLogFileHandle.(fn{i}));
    end
  end
  % backward compatibility: map lf() -> lf('main') and lf(fd) -> lf('main',fd)
  if nargin == 0
    [r n] = admLogFile('main');
    return
  elseif ~isa(name, 'char')
    [r n] = admLogFile('main', name);
    return
  end
  if ~isfield(adimatLogFileHandle, name)
    error('adimat:admLogFile:invalidCategory', ...
          'Logfile category name ''%s'' is not allowed', name);
  end
  r = adimatLogFileHandle.(name);
  n = adimatLogFileName.(name);
  if nargin > 1
    if isa(fh, 'char')
      fname = fh;
      if strcmp(adimatLogFileName.(name), fname)
        % file with that name is already open
        fh = adimatLogFileHandle.(name);
      else
        [a b c] = fileparts(fname);
        if exist(fname, 'file') || isempty(a) || exist(a, 'dir')
          fh = fopen(fname, 'w');
          if fh == -1
            error('adimat:admLogFile:couldNotOpenFile', ...
                  'file %s could not be opened', fname);
          end
        else
          error('adimat:admLogFile:fileNotFound', ...
                ['file %s does not exist and directory %s does not ' ...
                 'exist either'], fname, a);
        end
      end
    end
    adimatLogFileName.(name) = fopen(fh);
    adimatLogFileHandle.(name) = fh;
  end

% $Id: admLogFile.m 5054 2015-09-15 20:24:49Z willkomm $
