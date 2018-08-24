% function [dz, z] = dpartial_besselh(nu, k, x, opt?)
%
% Compute partial derivative diagonal of z = besselh(nu, k, x, opt)
% w.r.t. x.
%
% see also dpartial_exp.
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [dz z] = dpartial_besselh(nu, k, x, varargin)
  [z] = besselh(nu, k, x, varargin{:});
  if nu == 0
    [dz] = besselh(nu + 1, k, x, varargin{:});
    dz = -dz;
  else
    [dz] = besselh(nu - 1, k, x, varargin{:});
    dz = dz  - (nu ./ x) .* z;
  end
  if length(varargin)
    switch k
     case 1
      dz = dz + z .* -i;
     case 2
      dz = dz + z .* i;
    end
  end
% $Id: dpartial_besselh.m 3655 2013-05-22 11:36:56Z willkomm $
