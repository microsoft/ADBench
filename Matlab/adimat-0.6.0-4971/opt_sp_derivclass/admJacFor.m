% function Jac = admJacFor(varargin)
%
% This file is part of the ADiMat runtime environment, and belongs
% to the opt_derivclass derivative class.
%
% Copyright 2014 Johannes Willkomm
% Copyright 2009,2010 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admJacFor(varargin)
  nCompInResult = admTotalNumel(varargin{:});

  ndd = prod(admGetNDD(varargin{1}));
  Jac = zeros(nCompInResult, ndd);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    derivs = get(arg, 'deriv');
    for i=1:ndd
      Jac(resStart:resEnd, i) = derivs{i}(:);
    end
  end

% $Id: admJacFor.m 4441 2014-06-05 13:15:15Z willkomm $
