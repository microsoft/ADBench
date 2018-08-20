% function [dpartial y] = dpartial_sqrt(x)
%
% Compute partial derivative diagonal of y = sqrt(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_sqrt(x)
  y = sqrt(x);
  dpartial = 0.5 ./ y;

% $Id: dpartial_sqrt.m 3246 2012-03-23 14:38:47Z willkomm $
