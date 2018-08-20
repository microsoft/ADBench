% function [dpartial y] = dpartial_tand(x)
%
% Compute partial derivative diagonal of y = tand(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_tand(x)
  dpartial = (pi./180) .* secd(x) .^ 2;
  if nargout > 1
    y = tand(x);
  end

% $Id: dpartial_tand.m 3248 2012-03-24 10:51:47Z willkomm $
