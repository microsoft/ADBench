% function [r, newerList] = admCheckTransformedFileExists(functionName)
%
% Copyright 2011 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
% Copyright 2017 Johannes Willkomm
%
% This file is part of the ADiMat runtime environment.
%
function [r, newerList] = admCheckTransformedFileExists(functionName)
  while ~exist(functionName)
    if exist('rehash')
      rehash();
    end
    if exist('pause')
      if admIsOctave()
        % newer octave
        pause(0.01);
      else
        % matlab
        r = pause('query');
        pause('on');
        pause(0.01);
        pause(r);
      end
    else
      % elder octave
      sleep(1);
    end
    if ~exist([functionName '.m'])
      error('adimat:admCheckTransformedFileExists:transformedFileNotFound', ...
            'The transformed file %s does not exist\n', ...
            functionName);
      break
    end
  end
