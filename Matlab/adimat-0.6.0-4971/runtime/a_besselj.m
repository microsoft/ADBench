% function [adj] = a_besselj(adj, nu, x, opt?)
%
% compute the adjoint of x in z = besselj(nu, x, opt?), where adj is
% the adjoint of z.
%
% see also dpartial_besselj
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [adj] = a_besselj(adj, nu, x, varargin)
  if isempty(nu) || isempty(x)
    adj = a_zeros(x);
  else
    adj = adimat_adjred(x, dpartial_besselj(nu, x, varargin{:}) .* adj);
  end
% $Id: a_besselj.m 3874 2013-09-24 13:15:15Z willkomm $
