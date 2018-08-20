% function a_x = a_complex(x, y, a_z)
%
% Compute adjoint a_x of z = complex(x, y), where a_z is the adjoint of z.
%
% This file is part of the ADiMat runtime environment
%
% Copyright (c) 2016 Johannes Willkomm
function a_x = a_complex1(x, y, a_z)
  a_x = adimat_adjred(x, real(a_z));

% $Id: a_complex1.m 5110 2016-05-29 22:03:20Z willkomm $
