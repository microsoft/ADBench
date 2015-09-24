% function [a_b, z] = adimat_a_mpowerr(a, b, a_z)
%
% Compute adjoints a_b of z = a^b, matrix exponentiation. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012,2014 Johannes Willkomm
%
function [a_b, z] = adimat_a_mpowerr(a, b, a_z)
  [~, a_b, z] = adimat_a_mpower(a, b, a_z);

% $Id: adimat_a_mpowerr.m 4153 2014-05-11 16:35:51Z willkomm $
  