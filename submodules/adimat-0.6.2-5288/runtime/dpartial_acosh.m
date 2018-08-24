% function [dpartial y] = dpartial_acosh(x)
%
% Compute partial derivative diagonal of y = acosh(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acosh(x)
  dpartial = 1 ./ (sqrt(x + 1) .* sqrt(x - 1));
  if nargout > 1
    y = acosh(x);
  end

% $Id: dpartial_acosh.m 3262 2012-04-10 17:17:14Z willkomm $
