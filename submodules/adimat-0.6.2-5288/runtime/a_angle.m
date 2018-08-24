% function a_x = a_angle(a_z, x)
%
% Compute adjoint of z = angle(x), where a_z is the adjoint of z.
%
% see also a_atan2
%
% Copyright (c) 2016 Johannes Willkomm
function a_x = a_angle(a_z, x)
  t1 = real(x);
  t2 = imag(x);
  divi = (t2.^2 + t1.^2);
  a_zr = real(a_z);
  a_x = complex(-a_zr .* t2, -a_zr .* t1) ./ divi;

% $Id: a_angle.m 5109 2016-05-29 22:02:31Z willkomm $
