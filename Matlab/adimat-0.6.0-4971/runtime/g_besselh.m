% function [z, g_z] = g_besselh(nu, g_x, x, opt?)
%
% compute the derivative of z in z = besselh(nu, x, opt?), where g_x
% is the derivative of x.
%
% see also dpartial_besselj
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [z, g_z] = g_besselh(nu, k, g_x, x, varargin)
  if isempty(nu) || isempty(x)
    z = besselh(nu, k, x);
    g_z = g_zeros(size(z));
  else
    [p z] = dpartial_besselh(nu, k, x, varargin{:});
    g_z = p .* g_x;
  end
% $Id: g_besselh.m 3875 2013-09-24 13:37:48Z willkomm $
