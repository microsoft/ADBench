% function [dpartial y] = dpartial_cot(x)
%
% Compute partial derivative diagonal of y = cot(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_cot(x)
  dpartial = -csc(x).^2;
  if nargout > 1
    y = cot(x);
  end
  
% $Id: dpartial_cot.m 3246 2012-03-23 14:38:47Z willkomm $
