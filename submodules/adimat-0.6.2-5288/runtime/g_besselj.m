% function [z, g_z] = g_besselj(nu, g_x, x, opt?)
%
% compute the derivative of z in z = besselj(nu, x, opt?), where g_x
% is the derivative of x.
%
% see also dpartial_besselj
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [z, g_z] = g_besselj(nu, g_x, x, varargin)
  if isempty(nu) || isempty(x)
    z = besselj(nu, x);
    g_z = g_zeros(size(z));
  else
    [p z] = dpartial_besselj(nu, x, varargin{:});
    g_z = p .* g_x;
  end
% $Id: g_besselj.m 3875 2013-09-24 13:37:48Z willkomm $
