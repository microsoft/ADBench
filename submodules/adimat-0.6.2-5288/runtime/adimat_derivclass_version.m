% function [dcv dck] = adimat_derivclass_version()
%   get the version and revision of the derivative class ADiMat
%   dcv - derivative class version number: a double value
%   dck - derivative class name and version string
%
% Copyright 2010 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [dcv dcn dck] = adimat_derivclass_version()
  gd = g_zeros(1);
  if isa(gd, 'double')
    [dcv dcn dck] = adimat_derivclass_version_local();
  else
    dcv = get(g_dummy, 'DerivativeClassVersion');
    dcn = get(g_dummy, 'DerivativeClassName');
    dck = get(g_dummy, 'DerivativeClassKind');
  end

% $Id: adimat_derivclass_version.m 4289 2014-05-21 13:40:29Z willkomm $
