% function [dpartial y] = dpartial_asecd(x)
%
% Compute partial derivative diagonal of y = asecd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_asecd(x)
  dpartial = (180 ./ pi) .* dpartial_asec(x);
  if nargout > 1
    y = asecd(x);
  end

% $Id: dpartial_asecd.m 3262 2012-04-10 17:17:14Z willkomm $
