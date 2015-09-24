% function [g_r, r] = g_roots(g_c, c)
%   Compute derivative of r = roots(c). Also return the
%   function result r.
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
function [g_x, x] = g_roots(g_c, c)
  [partial x] = partial_roots(c);

  g_x = partial * g_c(:);

% $Id: g_roots.m 3176 2012-03-06 21:05:39Z willkomm $
% Local Variables:
% coding: utf-8
% End:
