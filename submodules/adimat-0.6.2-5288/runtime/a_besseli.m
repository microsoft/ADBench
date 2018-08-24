% function [adj] = a_besseli(adj, nu, x, opt?)
%
% compute the adjoint of x in z = besseli(nu, x, opt?), where adj is
% the adjoint of z.
%
% see also dpartial_besseli
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function [adj] = a_besseli(adj, nu, x, varargin)
  if isempty(nu) || isempty(x)
    adj = a_zeros(x);
  else
    adj = adimat_adjred(x, dpartial_besseli(nu, x, varargin{:}) .* adj);
  end
% $Id: a_besseli.m 3875 2013-09-24 13:37:48Z willkomm $
