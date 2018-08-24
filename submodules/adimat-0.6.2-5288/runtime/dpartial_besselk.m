% function [dz, z] = dpartial_besselk(nu, x, opt?)
%
% Compute partial derivative diagonal of z = besselk(nu, x, opt)
% w.r.t. x.
%
% This function uses Abramowitz and Stegun, 10th printing, 1972,
% p. 376, 9.6.26, fourth eq.
% cf. http://people.math.sfu.ca/~cbm/aands/page_376.htm
% or http://people.maths.ox.ac.uk/~macdonald/aands/page_376.htm
%
% This allows us to compute the derivative reusing the function
% result.
%
% see also dpartial_bessel_mod, dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dz z] = dpartial_besselk(nu, x, varargin)
  [z] = besselk(nu, x, varargin{:});
  [dz] = besselk(nu + 1, x, varargin{:});
  if nu == 0
    dz = -dz;
  else
    dz = -dz + (nu ./ x) .* z;
  end
  if length(varargin)
    % consider scaling of result by exp(x)
    dz = dz + z;
  end
% $Id: dpartial_besselk.m 3655 2013-05-22 11:36:56Z willkomm $
