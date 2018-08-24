% function [dcv dck] = adimat_derivclass_version_local()
%   get the version and revision of the derivative class ADiMat
%   dcv - derivative class version number: a double value
%   dck - derivative class name and version string
%
% Copyright 2018 Johannes Willkomm
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [dcv dcn dck] = adimat_derivclass_version_local()
  dcv = 0.3;
  dcn = 'double';
  dck = sprintf('scalar %g', dcv);

% Local Variables:
% mode: matlab
% End:
