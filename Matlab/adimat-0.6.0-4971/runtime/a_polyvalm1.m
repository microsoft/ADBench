% function [a_p] = a_polyval(a_z, p, x)
%
% Compute adjoint of p in z = polyvalm(p, x), matrix polynomial p(x),
% given the adjoint of z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [a_p z] = a_polyval1(a_z, p, x)
  deg = length(p);
  n = numel(x);
  
  a_p = a_zeros(p);

  xp = eye(size(x));
  
  for i=deg:-1:1
    a_p(i) = adimat_allsum(xp .* a_z);
    xp = xp * x;
  end

% $Id: a_polyvalm1.m 3303 2012-06-07 10:48:55Z willkomm $
