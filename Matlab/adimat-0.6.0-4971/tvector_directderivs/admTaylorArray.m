% function T = admTaylorArray(varargin)
%   concatenate a number of derivative objects to a Jacobian matrix
%
% This file is part of the ADiMat runtime environment, and belongs
% to the tvector_directderivs derivative "class".
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function Jac = admTaylorArray(varargin)
  ndd = size(varargin{1}, 1);
  maxOrder = size(varargin{1}, 2);
  nCompInResult = admGetTotalNumel(varargin{:}) ./ (max(ndd, 1).*maxOrder);
  Jac = zeros(nCompInResult, ndd, maxOrder);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg)) ./ (ndd.*maxOrder);
    for i=1:ndd
      for o=1:maxOrder
        dd = arg(i, o, :);
        Jac(resStart:resEnd, i, o) = dd(:);
      end
    end
  end

% $Id: admTaylorArray.m 3198 2012-03-09 12:00:11Z willkomm $
