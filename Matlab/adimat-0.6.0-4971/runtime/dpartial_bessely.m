% function [dz, z] = dpartial_bessely(nu, x, opt?)
%
% Compute partial derivative diagonal of z = bessely(nu, x, opt)
% w.r.t. x.
%
% see also dpartial_bessel, dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dz z] = dpartial_bessely(nu, x, varargin)
  [dz z] = dpartial_bessel(@bessely, nu, x, varargin{:});
% $Id: dpartial_bessely.m 3655 2013-05-22 11:36:56Z willkomm $
