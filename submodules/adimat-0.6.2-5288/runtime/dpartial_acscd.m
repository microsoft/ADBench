% function [dpartial y] = dpartial_acscd(x)
%
% Compute partial derivative diagonal of y = acscd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_acscd(x)
  dpartial = (180 ./ pi) .* dpartial_acsc(x);
  if nargout > 1
    y = acscd(x);
  end

% $Id: dpartial_acscd.m 3262 2012-04-10 17:17:14Z willkomm $
