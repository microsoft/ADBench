% function [dpartial y] = dpartial_cscd(x)
%
% Compute partial derivative diagonal of y = cscd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_cscd(x)
  y = cscd(x);
  dpartial = (-pi./180) .* cotd(x) .* y;
  
% $Id: dpartial_cscd.m 3248 2012-03-24 10:51:47Z willkomm $
