% function [g_z z] = adimat_g_power(g_a, a, g_b, b)
%
% Compute derivative of z = a.^b, exponentiation. Also return the
% function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_pow(g_a, a, g_b, b)
  z = a.^b;
  
  g_z = g_a .* b .* z ./ a;
  g_z = g_z + g_b .* log(a) .* z;

% $Id: adimat_g_power.m 3309 2012-06-18 09:53:52Z willkomm $
