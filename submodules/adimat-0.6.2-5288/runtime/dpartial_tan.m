% function [dpartial y] = dpartial_tan(x)
%
% Compute partial derivative diagonal of y = tan(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_tan(x)
  dpartial = sec(x) .^ 2;
  if nargout > 1
    y = tan(x);
  end

% $Id: dpartial_tan.m 3246 2012-03-23 14:38:47Z willkomm $
