% function [dpartial y] = dpartial_tanh(x)
%
% Compute partial derivative diagonal of y = tanh(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_tanh(x)
  dpartial = sech(x) .^ 2;
  if nargout > 1
    y = tanh(x);
  end

% $Id: dpartial_tanh.m 3246 2012-03-23 14:38:47Z willkomm $
