% function T2 = admTaylor2For(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admTaylor2For(varargin)
  nCompInResult = 0;
  for i=1:nargin
    nCompInResult = nCompInResult + prod(size(varargin{i}));
  end
  ndd = sqrt(admGetNDD(varargin{1}));
  Jac = zeros(nCompInResult, ndd);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    for i=1:ndd
      data = arg{i,i};
      Jac(resStart:resEnd, i) = data(:);
    end
  end

% $Id: admTaylor2For.m 3260 2012-04-03 08:31:34Z willkomm $
