% function [dpartial y] = dpartial_secd(x)
%
% Compute partial derivative diagonal of y = secd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_secd(x)
  y = secd(x);
  dpartial = (pi./180) .* tand(x).*y;

% $Id: dpartial_secd.m 3248 2012-03-24 10:51:47Z willkomm $
