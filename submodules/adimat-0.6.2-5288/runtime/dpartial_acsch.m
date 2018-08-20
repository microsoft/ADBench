% function [dpartial y] = dpartial_acsch(x)
%
% Compute partial derivative diagonal of y = acsch(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acsch(x)
  dpartial = -1 ./ (x .^ 2 .* sqrt(1 + 1 ./ x.^2));
  if nargout > 1
    y = acsch(x);
  end

% $Id: dpartial_acsch.m 3262 2012-04-10 17:17:14Z willkomm $
