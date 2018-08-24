% function [dpartial y] = dpartial_acosd(x)
%
% Compute partial derivative diagonal of y = acosd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acosd(x)
  dpartial = (180 ./ pi) .* dpartial_acos(x);
  if nargout > 1
    y = acosd(x);
  end

% $Id: dpartial_acosd.m 3262 2012-04-10 17:17:14Z willkomm $
