% function [a_x] = a_logm(a_z, x)
%
% Compute adjoint of x in z = logm(x), matrix logarithm, given the
% adjoint of z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [a_x] = a_logm(a_z, x)
  [partial z] = partial_logm(x);
  a_x = reshape(a_z(:).' * partial, size(x));
% $Id: a_logm.m 3255 2012-03-28 14:32:56Z willkomm $
