% function [a_x] = a_diag(a_z, x, k)
%
% Compute adjoint of x in z = diag(x, k), given the adjoint of z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [a_x] = a_diag(a_z, x, k)
  if nargin < 3
    k = 0;
  end
  szx = size(x);
  if isvector(x)
    a_x = call(@diag, a_z, k);
    a_x = reshape(a_x, size(x));
  else
    if szx(1) == szx(2) % square
      a_x = call(@diag, a_z, k);
    else
      a_x = a_zeros(x);
      if k >= 0
        for i=1:min(szx(1), szx(2)-k)
          a_x(i,i+k) = a_z(i);
        end
      else
        for i=1:min(szx(1)+k, szx(2))
          a_x(i-k,i) = a_z(i);
        end
      end
    end
  end
% $Id: a_diag.m 3311 2012-06-19 16:04:34Z willkomm $
