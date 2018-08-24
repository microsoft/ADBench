% function [dpartial y] = dpartial_cos(x)
%
% Compute partial derivative diagonal of y = cos(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_cos(x)
  dpartial = -sin(x);
  if nargout > 1
    y = cos(x);
  end
  
% $Id: dpartial_cos.m 3246 2012-03-23 14:38:47Z willkomm $
