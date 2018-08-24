% function [dpartial y] = dpartial_asec(x)
%
% Compute partial derivative diagonal of y = asec(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_asec(x)
  dpartial = sign(real(x)) ./ (x .* sqrt(x.^2 - 1));
  if nargout > 1
    y = asec(x);
  end

% $Id: dpartial_asec.m 3246 2012-03-23 14:38:47Z willkomm $
