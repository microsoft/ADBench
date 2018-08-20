% function [dpartial y] = dpartial_cotd(x)
%
% Compute partial derivative diagonal of y = cotd(x).
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dpartial y] = dpartial_cotd(x)
  dpartial = (-pi./180) .* cscd(x).^2;
  if nargout > 1
    y = cotd(x);
  end
  
% $Id: dpartial_cotd.m 3248 2012-03-24 10:51:47Z willkomm $
