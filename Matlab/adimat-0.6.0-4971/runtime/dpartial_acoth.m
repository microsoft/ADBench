% function [dpartial y] = dpartial_acoth(x)
%
% Compute partial derivative diagonal of y = acoth(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acoth(x)
  dpartial = 1 ./ (1 - x .^ 2);
  if nargout > 1
    y = acoth(x);
  end
% $Id: dpartial_acoth.m 3246 2012-03-23 14:38:47Z willkomm $
