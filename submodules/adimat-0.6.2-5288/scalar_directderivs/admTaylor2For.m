% function T2 = admTaylor2For(varargin)
%
% This file is part of ADiMat, and belongs to the scalar_directderivs
% runtime environment.
%
% Copyright 2009-2011 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admTaylor2For(varargin)
  nCompInResult = 0;
  for i=1:nargin
    nCompInResult = nCompInResult + prod(size(varargin{i}));
  end
  Jac = zeros(nCompInResult, 1);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    Jac(resStart:resEnd) = arg(:);
  end

% $Id: admTaylor2For.m 3068 2011-10-11 17:45:10Z willkomm $
