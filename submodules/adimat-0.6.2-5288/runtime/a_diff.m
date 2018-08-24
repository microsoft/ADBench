% function a_x = a_diff(a_z, x, n?, i?)
%
% Compute adjoint x in z = diff(x, n, i) from a_z.
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function a_x = a_diff(a_z, x, n, dimind)
  if nargin < 3
    n = 1;
  end
  if nargin < 4
    dimind = adimat_first_nonsingleton(x);
  end
  
  if n == 1
    
    szz = size(a_z);
    sze = szz; 
    sze(dimind) = 1;
    zelem = a_zeros(zeros(sze));
    p1 = cat(dimind, zelem, a_z);
    p2 = cat(dimind, a_z, zelem);
    a_x = p1 - p2;
    
  else

    for i=1:n
      a_z = a_diff(a_z, x, 1, dimind);
    end
    a_x = a_z;
    
  end
  
% $Id: a_diff.m 4510 2014-06-13 13:57:17Z willkomm $
