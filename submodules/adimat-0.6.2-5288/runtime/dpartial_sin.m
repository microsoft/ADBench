% function [dpartial y] = dpartial_sin(x)
%
% Compute partial derivative diagonal of y = sin(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_sin(x)
  dpartial = cos(x);
  if nargout > 1
    y = sin(x);
  end

% $Id: dpartial_sin.m 3246 2012-03-23 14:38:47Z willkomm $
