% function [d_z z] = d_polyvalm(d_p, p, d_x, x)
%
% Compute derivative of z in z = polyval(p, x), matrix polynomial
% p(x), given the derivatives of p and x.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [d_z z] = d_polyvalm(d_p, p, d_x, x)
  deg = length(p);
  szx = size(x);
  ndd = size(d_x, 1);
  
  Id = ones(szx(1), 1);
  
  d_z = d_zeros(x);
  for dd=1:ndd
    d_z(dd,:,:) = diag(d_p(dd,1) .* Id);
  end
  z = diag(p(1) .* Id);
  for i=2:deg
    for dd=1:ndd
      d_z(dd,:,:) = squeeze(d_x(dd,:,:)) * z + x * squeeze(d_z(dd,:,:)) + diag(d_p(dd,i) .* Id);
    end
    z = x * z + diag(p(i) .* Id);
  end

% $Id: d_polyvalm.m 3303 2012-06-07 10:48:55Z willkomm $
