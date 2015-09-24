% function [versionNumber versionString version revision] = adimat_version(which)
%   get the version of ADiMat
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [a b c d] = adimat_version(which)
  if nargin > 0
    [res{1:4}] = adimat_version();
    a = res{which};
  else
    a = 0.60;
    b = 'ADiMat 0.6.0-4971';
    c = '0.6.0';
    d = '4971';
  end

% Local Variables:
% mode: MATLAB
% End:

% $Id: adimat_version.template 2997 2011-06-21 15:30:11Z willkomm $
