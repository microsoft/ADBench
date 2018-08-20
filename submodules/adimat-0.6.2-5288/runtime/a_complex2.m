% function a_y = a_complex(x, y, a_z)
%
% Compute adjoint a_y of z = complex(x, y), where a_z is the adjoint of z.
%
% Copyright (c) 2016 Johannes Willkomm
function a_y = a_complex2(x, y, a_z)
  a_y = adimat_adjred(y, -imag(a_z));

% $Id: a_complex2.m 5110 2016-05-29 22:03:20Z willkomm $
