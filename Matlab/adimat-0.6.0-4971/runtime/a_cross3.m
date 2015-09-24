% function adj = a_cross3(a_z, ind, a, b, dim)
%  when ind == 1, compute adjoint of a in z = cross(a, b, dim)
%  when ind == 2, compute adjoint of b in z = cross(a, b, dim)
%  where a_z is the adjoint of z.
%
% see also a_zeros, a_sum
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function adj = a_cross3(a_z, ind, a, b, dim)

  % z(1) = a(2) .* b(3) - a(3) .* b(2);
  % z(2) = a(3) .* b(1) - a(1) .* b(3);
  % z(3) = a(1) .* b(2) - a(2) .* b(1);
  
  sza = size(a); % == size(b)
  inds1 = cell(1, length(sza));
  for i=1:length(sza)
    inds1{i} = ':';
  end
  inds2 = inds1;
  inds3 = inds1;
  inds1{dim} = 1;
  inds2{dim} = 2;
  inds3{dim} = 3;
    
  adj = a_zeros(a);

  switch ind
   case 1
    adj(inds1{:}) = a_z(inds3{:}) .* b(inds2{:}) - a_z(inds2{:}) .* b(inds3{:});
    adj(inds2{:}) = a_z(inds1{:}) .* b(inds3{:}) - a_z(inds3{:}) .* b(inds1{:});
    adj(inds3{:}) = a_z(inds2{:}) .* b(inds1{:}) - a_z(inds1{:}) .* b(inds2{:});
   case 2
    adj(inds1{:}) = a_z(inds2{:}) .* a(inds3{:}) - a_z(inds3{:}) .* a(inds2{:});
    adj(inds2{:}) = a_z(inds3{:}) .* a(inds1{:}) - a_z(inds1{:}) .* a(inds3{:});
    adj(inds3{:}) = a_z(inds1{:}) .* a(inds2{:}) - a_z(inds2{:}) .* a(inds1{:});
  end

% $Id: a_cross3.m 3547 2013-04-04 11:45:26Z willkomm $
