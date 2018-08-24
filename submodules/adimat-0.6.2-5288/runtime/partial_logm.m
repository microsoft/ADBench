% function [partial z] = partial_logm(x)
%
% Compute partial derivative of z = logm(x). Also return the function
% result z.
%
% partial is computed as the matrix inverse of partial_expm(logm(x)).
%
% see also g_logm, a_logm
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_logm(x, base)
  if nargin < 2
    base = eye(numel(x));
  end
  ndd = size(base, 2);
  z = logm(x);
  p_expm = partial_expm(z);
  partial = p_expm \ base;

% $Id: partial_logm.m 3255 2012-03-28 14:32:56Z willkomm $
