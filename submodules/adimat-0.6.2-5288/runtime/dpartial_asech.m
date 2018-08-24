% function [dpartial y] = dpartial_asech(x)
%
% Compute partial derivative diagonal of y = asech(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_asech(x)
  xp1 = x + 1;
  dpartial = -1 ./ (x .* xp1 .* sqrt((1-x)./xp1));
  if nargout > 1
    y = asech(x);
  end

% $Id: dpartial_asech.m 3246 2012-03-23 14:38:47Z willkomm $
