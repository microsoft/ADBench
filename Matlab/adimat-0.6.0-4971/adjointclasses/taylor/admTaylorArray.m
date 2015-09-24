% function T = admTaylorArray(varargin)
%   concatenate a number of derivative objects to a Jacobian matrix
%
% This file is part of the ADiMat runtime environment, and belongs
% to the tseries derivative class.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
% Copyright 2001-2009 Andre Vehreschild, Institute for Scientific Computing
%                     RWTH Aachen University
function TA = admTaylorArray(varargin)
  nCompInResult = sum(cellfun('prodofsize', varargin));
  maxOrder = get(varargin{1}, 'maxorder');
  if maxOrder > 0
    ndd = admGetNDD(varargin{1}{2});
  else
    ndd = 1;
  end
  TA = zeros(nCompInResult, ndd, maxOrder);
  resStart = 0;
  resEnd = 0;
  for argi=1:nargin
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    for i=1:ndd
      for o=1:maxOrder
        dd = admGetDD(arg{o+1}, i);
        TA(resStart:resEnd, i, o) = dd(:);
      end
    end
  end

% $Id: admTaylorArray.m 3472 2012-11-26 11:04:52Z willkomm $
