% function T = admTaylorArray(varargin)
%   concatenate a number of derivative objects to a Jacobian matrix
%
% This file is part of the ADiMat runtime environment, and belongs
% to the tseries derivative class.
%
% Copyright (C) 2015 Johannes Willkomm
% Copyright (C) 2010-2012 Johannes Willkomm, Institute for Scientific Computing
function TA = admTaylorArray(varargin)
  maxOrder = get(varargin{1}, 'maxorder');
  if maxOrder > 0
    ndd = admGetNDD(varargin{1}{2});
  else
    ndd = 1;
  end
  TA = admTaylorArrayInt(maxOrder, ndd, varargin{:});
% $Id: admTaylorArray.m 4899 2015-02-16 21:37:49Z willkomm $
