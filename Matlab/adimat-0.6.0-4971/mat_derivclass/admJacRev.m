% function Jac = admJacRev(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admJacRev(varargin)
  nCompInArgs = 0;
  for i=1:nargin
    nCompInArgs = nCompInArgs + prod(size(varargin{i}));
  end
  ndd = prod(admGetNDD(varargin{1}));
  Jac = zeros(ndd, nCompInArgs);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    for i=1:ndd
      Jac(i, resStart:resEnd) = arg{i}(:);
    end
  end

% $Id: admJacRev.m 4234 2014-05-17 13:39:07Z willkomm $
