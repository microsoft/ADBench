% function [adj] = a_besselh(adj, nu, k, x, opt?)
%
% compute the adjoint of x in z = besselh(nu, k, x, opt?), where adj
% is the adjoint of z.
%
% see also dpartial_besselh
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [adj] = a_besselh(adj, nu, k, x, varargin)
  if isempty(nu) || isempty(x)
    adj = a_zeros(x);
  else
    adj = adimat_adjred(x, dpartial_besselh(nu, k, x, varargin{:}) .* adj);
  end
% $Id: a_besselh.m 3875 2013-09-24 13:37:48Z willkomm $
