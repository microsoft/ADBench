function [r, newerList] = admCheckTransformedFileExists(functionName)
  while ~exist(functionName)
    if exist('rehash')
      rehash();
    end
    if ~exist('sleep')
      % matlab
      r = pause('query');
      pause('on');
      pause(0.01);
      pause(r);
    else
      % octave
      sleep(1);
    end
    if ~exist([functionName '.m'])
      error('adimat:admCheckTransformedFileExists:transformedFileNotFound', ...
            'The transformed file %s does not exist\n', ...
            functionName);
      break
    end
  end
% $Id: admCheckTransformedFileExists.m 2543 2011-01-24 12:22:13Z willkomm $
