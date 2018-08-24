% function a_c = a_roots(a_r, c)
%   Compute adjoint of r = roots(c).
%
% Computation according to ansatz from Martin Bücker using implicit
% function theorom.
%
% see also partial_roots
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2011-2012 H.Martin Bücker, Institute for Scientific Computing
% Copyright 2011-2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [a_c] = a_roots(a_r, c)
  partial = partial_roots(c);

  a_c = a_r .' *  partial;

  if any(size(c) ~= size(a_c))
    a_c = a_c .';
  end

% $Id: a_roots.m 3206 2012-03-12 14:03:12Z willkomm $
% Local Variables:
% coding: utf-8
% End:
