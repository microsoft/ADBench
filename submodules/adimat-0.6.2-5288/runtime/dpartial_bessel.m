% function [dz, z] = dpartial_bessel(besfun, nu, x, opt?)
%
% Compute partial derivative diagonal of z = besfun(nu, x, opt)
% w.r.t. x, where besfun is one of besselj or bessely.
%
% This function uses Abramowitz and Stegun, 10th printing, 1972,
% p. 361, 9.1.27, third eq.
% cf. http://people.math.sfu.ca/~cbm/aands/page_361.htm
% or http://people.maths.ox.ac.uk/~macdonald/aands/page_361.htm
%
% This allows us to compute the derivative with just one additional
% call, instead of two (second eq), reusing the function result.
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dz z] = dpartial_bessel(besfun, nu, x, varargin)
  [z] = besfun(nu, x, varargin{:});
  if nu == 0
    [dz] = besfun(nu + 1, x, varargin{:});
    dz = -dz;
  else
    [dz] = besfun(nu - 1, x, varargin{:});
    dz = dz - (nu ./ x) .* z;
  end
% $Id: dpartial_bessel.m 3655 2013-05-22 11:36:56Z willkomm $
