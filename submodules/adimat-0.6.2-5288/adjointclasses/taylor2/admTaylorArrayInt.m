% function T = admTaylorArrayInt(varargin)
%   concatenate a number of derivative objects to a Jacobian matrix
%
% This file is part of the ADiMat runtime environment, and belongs
% to the tseries derivative class.
%
% Copyright (C) 2015 Johannes Willkomm
% Copyright (C) 2010-2012 Johannes Willkomm, Institute for Scientific Computing
function TA = admTaylorArrayInt(maxOrder, ndd, varargin)
  nCompInResult = sum(cellfun('prodofsize', varargin));
  TA = zeros(nCompInResult, ndd, maxOrder);
  resStart = 0;
  resEnd = 0;
  for argi=1:length(varargin)
    arg = varargin{argi};
    resStart = resEnd + 1;
    resEnd = resEnd + prod(size(arg));
    if isobject(arg)
      for o=1:maxOrder
        derivs = admJacFor(arg{o+1});
        TA(resStart:resEnd, :, o) = derivs;
      end
    % else all zero block
    end
  end
% $Id: admTaylorArrayInt.m 4885 2015-02-16 11:00:46Z willkomm $
