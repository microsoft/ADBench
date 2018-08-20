% function [z, g_z] = g_besseli(nu, g_x, x, opt?)
%
% compute the derivative of z in z = besseli(nu, x, opt?), where g_x
% is the derivative of x.
%
% see also dpartial_besseli
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [z, g_z] = g_besseli(nu, g_x, x, varargin)
  if isempty(nu) || isempty(x)
    z = besseli(nu, x);
    g_z = g_zeros(size(z));
  else
    [p z] = dpartial_besseli(nu, x, varargin{:});
    g_z = p .* g_x;
  end
% $Id: g_besseli.m 3875 2013-09-24 13:37:48Z willkomm $
