% function [dpartial y] = dpartial_sech(x)
%
% Compute partial derivative diagonal of y = sech(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_sech(x)
  y = sech(x);
  dpartial = -tanh(x) .* y;

% $Id: dpartial_sech.m 3246 2012-03-23 14:38:47Z willkomm $
