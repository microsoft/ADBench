% function [z, g_z] = a_besselk(nu, g_x, x, opt?)
%
% compute the derivative of z in z = besselk(nu, x, opt?), where g_x
% is the derivative of x.
%
% see also dpartial_besselk
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [z, g_z] = g_besselk(nu, g_x, x, varargin)
  if isempty(nu) || isempty(x)
    z = besselk(nu, x);
    g_z = g_zeros(size(z));
  else
    [p z] = dpartial_besselk(nu, x, varargin{:});
    g_z = p .* g_x;
  end
% $Id: g_besselk.m 3875 2013-09-24 13:37:48Z willkomm $
