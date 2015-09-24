% function [a_a, z] = adimat_a_mpowerl(a, b, a_z)
%
% Compute adjoint a_a of z = a^b, matrix exponentiation. Also
% return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012,2014 Johannes Willkomm
%
function [a_a, z] = adimat_a_mpowerl(a, b, a_z)
  % FIXME: Provide special version for this case
  [a_a, ~, z] = adimat_a_mpower(a, b, a_z);

% $Id: adimat_a_mpowerl.m 4153 2014-05-11 16:35:51Z willkomm $
  