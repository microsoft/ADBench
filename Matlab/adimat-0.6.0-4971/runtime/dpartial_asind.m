% function [dpartial y] = dpartial_asind(x)
%
% Compute partial derivative diagonal of y = asind(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_asind(x)
  dpartial = (180 ./ pi) .* dpartial_asin(x);
  if nargout > 1
    y = asind(x);
  end
  
% $Id: dpartial_asind.m 3262 2012-04-10 17:17:14Z willkomm $
