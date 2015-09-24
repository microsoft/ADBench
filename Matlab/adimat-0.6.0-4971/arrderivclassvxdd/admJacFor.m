% function Jac = admJacFor(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admJacFor(varargin)
  if nargin == 1
    Jac = get(varargin{1}, 'deriv');
  else
    nCompInResult = 0;
    for i=1:nargin
      nCompInResult = nCompInResult + prod(size(varargin{i}));
    end
    ndd = prod(admGetNDD(varargin{1}));
    Jac = zeros(nCompInResult, ndd);
    resStart = 0;
    resEnd = 0;
    for argi=1:nargin
      arg = varargin{argi};
      resStart = resEnd + 1;
      resEnd = resEnd + prod(size(arg));
      deriv = get(arg, 'deriv');
      Jac(resStart:resEnd, :) = deriv;
    end
  end
% $Id: admJacFor.m 4380 2014-05-30 09:53:05Z willkomm $
