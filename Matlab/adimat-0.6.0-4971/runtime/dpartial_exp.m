% function [dpartial y] = partial_exp(x)
%
% Compute partial derivative diagonal of y = exp(x).
%
% This returns the diagonal of the partial derivative. The partial
% derivative matrix can be obtained by using diag(dpartial).
%
% see also dpartial_sqrt, etc.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_exp(x)
  y = exp(x);
  dpartial = y;

% $Id: dpartial_exp.m 3247 2012-03-23 15:08:24Z willkomm $
