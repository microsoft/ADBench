% function [dpartial y] = dpartial_coth(x)
%
% Compute partial derivative diagonal of y = coth(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_coth(x)
  dpartial = -1 ./ sinh(x).^2;
  if nargout > 1
    y = coth(x);
  end

% $Id: dpartial_coth.m 3246 2012-03-23 14:38:47Z willkomm $
