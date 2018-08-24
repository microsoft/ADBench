% function [a_x z] = a_polyval2(a_z, p, x)
%
% Compute adjoint of x in z = polyval(p, x), polynomial p(x), given
% the adjoint of z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [a_x z] = a_polyval2(a_z, p, x)
  deg = length(p);
  n = numel(x);
  
  szx = size(x);
  x = reshape(x, [1 n]);
  a_z = reshape(a_z, [1 n]);
  
  Z = zeros(deg, n);
  Z(1,:) = p(1);
  for i=2:deg
    Z(i,:) = x .* Z(i-1,:) + p(i);
  end
  
  z = Z(deg,:);
  
  a_x = a_zeros(x);
  
  for i=deg:-1:2
    a_x = a_x + a_z .* Z(i-1,:);
    a_z = x .* a_z;
  end

  a_x = reshape(a_x, szx);
  
% $Id: a_polyval2.m 3303 2012-06-07 10:48:55Z willkomm $
