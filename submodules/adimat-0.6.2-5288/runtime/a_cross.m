% function adj = a_cross(a_z, ind, a, b)
%  when ind == 1, compute adjoint of a in z = cross(a, b)
%  when ind == 2, compute adjoint of b in z = cross(a, b)
%  where a_z is the adjoint of z.
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_cross(a_z, ind, a, b)

  % z(1) = a(2) .* b(3) - a(3) .* b(2);
  % z(2) = a(3) .* b(1) - a(1) .* b(3);
  % z(3) = a(1) .* b(2) - a(2) .* b(1);
  
  switch ind
   case 1
    adj = a_zeros(a);
    adj(1) = a_z(3) .* b(2) - a_z(2) .* b(3);
    adj(2) = a_z(1) .* b(3) - a_z(3) .* b(1);
    adj(3) = a_z(2) .* b(1) - a_z(1) .* b(2);
   case 2
    adj = a_zeros(b);
    adj(1) = a_z(2) .* a(3) - a_z(3) .* a(2);
    adj(2) = a_z(3) .* a(1) - a_z(1) .* a(3);
    adj(3) = a_z(1) .* a(2) - a_z(2) .* a(1);
  end

% $Id: a_cross.m 3536 2013-04-03 11:57:40Z willkomm $
