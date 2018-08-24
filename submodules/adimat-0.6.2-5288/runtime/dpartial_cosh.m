% function [dpartial y] = dpartial_cosh(x)
%
% Compute partial derivative diagonal of y = cosh(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_cosh(x)
  dpartial = sinh(x);
  if nargout > 1
    y = cosh(x);
  end

% $Id: dpartial_cosh.m 3246 2012-03-23 14:38:47Z willkomm $
