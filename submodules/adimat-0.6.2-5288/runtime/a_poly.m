% function a_c = a_poly(a_c, r)
%   Compute adjoint of c = poly(r).
%
% see also partial_poly
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     RWTH Aachen University
function a_r = a_poly(a_c, r)
  partial = partial_poly(r);

  a_r = a_c *  partial;

  if any(size(r) ~= size(a_r))
    a_r = a_r .';
  end

% $Id: a_poly.m 3196 2012-03-09 11:53:54Z willkomm $
% Local Variables:
% coding: utf-8
% End:
