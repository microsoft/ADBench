% function [a_x z] = a_polyvalm2(a_z, p, x)
%
% Compute adjoint of x in z = polyvalm(p, x), matrix polynomial p(x),
% given the adjoint of z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [a_x z] = a_polyvalm2(a_z, p, x)
  deg = length(p);
  szx = size(x);

  Id = ones(szx(1), 1);
  
  Z = zeros([szx, deg]);
  Z(:,:,1) = diag(p(1) .* Id);
  for i=2:deg
    Z(:,:,i) = x * Z(:,:,i-1) + diag(p(i) .* Id);
  end
  
  z = Z(:,:,deg);
  
  a_x = a_zeros(x);
  
  for i=deg:-1:2
    a_x = a_x + a_z * Z(:,:,i-1).';
    a_z = x.' * a_z;
  end
  
% $Id: a_polyvalm2.m 3973 2013-11-06 09:23:26Z willkomm $
