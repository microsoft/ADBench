% function [partial c] = partial_poly(r)
%   Compute partial derivative of c = poly(r). Also return the
%   function result c.
%
% see also g_poly, a_poly
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function [partial c] = partial_poly(r)
  deg = length(r);
  c = poly(r);
  partial = zeros(deg + 1, deg);
  for i=1:deg
    fp = r(1:i-1);
    sp = r(i+1:end);
    partial(:,i) = [0 -poly([fp(:); sp(:)])];
  end

% $Id: partial_poly.m 3178 2012-03-06 21:50:04Z willkomm $
% Local Variables:
% coding: utf-8
% End:
