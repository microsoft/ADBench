% function [dpartial y] = dpartial_sind(x)
%
% Compute partial derivative diagonal of y = sind(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_sind(x)
  dpartial = (pi./180) .* cosd(x);
  if nargout > 1
    y = sind(x);
  end

% $Id: dpartial_sind.m 3248 2012-03-24 10:51:47Z willkomm $
