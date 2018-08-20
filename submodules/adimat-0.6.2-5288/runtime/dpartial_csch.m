% function [dpartial y] = dpartial_csch(x)
%
% Compute partial derivative diagonal of y = csch(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_csch(x)
  y = csch(x);
  dpartial = -coth(x) .* y;
  
% $Id: dpartial_csch.m 3246 2012-03-23 14:38:47Z willkomm $
