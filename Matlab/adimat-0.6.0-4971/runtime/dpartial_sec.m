% function [dpartial y] = dpartial_sec(x)
%
% Compute partial derivative diagonal of y = sec(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_sec(x)
  y = sec(x);
  dpartial = tan(x).*y;

% $Id: dpartial_sec.m 3246 2012-03-23 14:38:47Z willkomm $
