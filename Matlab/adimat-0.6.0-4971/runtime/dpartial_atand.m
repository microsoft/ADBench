% function [dpartial y] = dpartial_atand(x)
%
% Compute partial derivative diagonal of y = atand(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_atand(x)
  dpartial = (180 ./ pi) .* dpartial_atan(x);
  if nargout > 1
    y = atand(x);
  end
  
% $Id: dpartial_atand.m 3262 2012-04-10 17:17:14Z willkomm $
