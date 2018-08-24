% function [dpartial y] = dpartial_acsc(x)
%
% Compute partial derivative diagonal of y = acsc(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acsc(x)
  dpartial = -sign(real(x)) ./ (x .* sqrt(x.^2 - 1));
  if nargout > 1
    y = acsc(x);
  end

% $Id: dpartial_acsc.m 3246 2012-03-23 14:38:47Z willkomm $
