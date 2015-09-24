% function [dpartial y] = dpartial_cosd(x)
%
% Compute partial derivative diagonal of y = cosd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_cosd(x)
  dpartial = (-pi./180) .* sind(x);
  if nargout > 1
    y = cosd(x);
  end
  
% $Id: dpartial_cosd.m 3248 2012-03-24 10:51:47Z willkomm $
