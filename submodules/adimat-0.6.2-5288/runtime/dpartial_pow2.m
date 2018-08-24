% function [dpartial y] = partial_pow2(x)
%
% Compute partial derivative diagonal of y = pow2(x).
%
% This returns the diagonal of the partial derivative. The partial
% derivative matrix can be obtained by using diag(partial).
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_pow2(x)
  y = pow2(x);
  dpartial = log(2) .* y;

% $Id: dpartial_pow2.m 3247 2012-03-23 15:08:24Z willkomm $
