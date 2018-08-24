% function [g_c, c] = g_poly(g_r, r)
%   Compute derivative of r = poly(c). Also return the
%   function result r.
%
% see also partial_poly
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [g_c, c] = g_poly(g_r, r)
  [partial c] = partial_poly(r);

  g_c = (partial * g_r(:)).';
  
% $Id: g_poly.m 3196 2012-03-09 11:53:54Z willkomm $
% Local Variables:
% coding: utf-8
% End:
