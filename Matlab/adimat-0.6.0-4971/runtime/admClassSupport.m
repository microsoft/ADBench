% function res = admClassSupport()
%
% This function returns true if run either
%
%  - in the Matlab interpreter
%  - in the Octave interpreter version 3.6 or higher
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
%
% This file is part of the ADiMat runtime environment.
%
function res = admClassSupport()
  if ~exist('printf', 'builtin') 
    % is MATLAB
    res = true;
  else
    res = admIsOctave(3.6);
  end
% $Id: admClassSupport.m 4577 2014-06-20 21:07:22Z willkomm $
