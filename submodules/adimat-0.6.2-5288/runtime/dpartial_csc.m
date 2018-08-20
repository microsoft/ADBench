% function [dpartial y] = dpartial_csc(x)
%
% Compute partial derivative diagonal of y = csc(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_csc(x)
  y = csc(x);
  dpartial = -cot(x).*y;
  
% $Id: dpartial_csc.m 3246 2012-03-23 14:38:47Z willkomm $
