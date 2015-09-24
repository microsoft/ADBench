% function [dpartial y] = dpartial_acotd(x)
%
% Compute partial derivative diagonal of y = acotd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acotd(x)
  dpartial = (180 ./ pi) .* dpartial_acot(x);
  if nargout > 1
    y = acotd(x);
  end
% $Id: dpartial_acotd.m 3262 2012-04-10 17:17:14Z willkomm $
