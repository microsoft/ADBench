% function [h_g_z g_z z] = adimat_h_mldivide2(a, h_b, g_b, b)
%
% Compute first and second order derivative of z = a \ b, matrix left
% division, with a constant. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2013,2014 Johannes Willkomm
%
function [h_g_z g_z z] = adimat_h_mldivide2(h_a, a, h_g_b, g_b, h_b, b)

  [m n] = size(a);
  
  z = a \ b;

  g_z = a \ g_b;
  h_g_z = a \ (h_g_b - h_a * g_z);

% $Id: adimat_h_mldivide2.m 4354 2014-05-25 16:26:47Z willkomm $
