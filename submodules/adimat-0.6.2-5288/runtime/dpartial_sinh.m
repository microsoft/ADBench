% function [dpartial y] = dpartial_sinh(x)
%
% Compute partial derivative diagonal of y = sinh(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_sinh(x)
  dpartial = cosh(x);
  if nargout > 1
    y = sinh(x);
  end

% $Id: dpartial_sinh.m 3246 2012-03-23 14:38:47Z willkomm $
