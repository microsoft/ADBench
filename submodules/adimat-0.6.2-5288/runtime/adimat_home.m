% function [h] = adimat_home()
%   get the home directory of ADiMat
%   h   - the home directory of ADiMat
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
%
% This file is part of the ADiMat runtime environment
%
function [h] = adimat_home()
  h = getenv('ADIMAT_HOME');
  if isempty(h)
    h = 'c:/adimat';
  end

% Local Variables:
% mode: MATLAB
% End:

% $Id: adimat_home.m.in 3680 2013-05-29 17:15:02Z willkomm $
