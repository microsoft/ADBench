% function [h_z g_z z] = adimat_h_mrdivide2(h_a, a, h_b, g_b, b)
%
% Compute first and second order derivative of z = a / b, matrix right
% division, with a constant. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2013,2014 Johannes Willkomm
%
function [h_g_z g_z z] = adimat_h_mrdivide2(h_a, a, h_g_b, g_b, h_b, b)

  [h_g_z g_z z] = adimat_h_mldivide1(h_g_b, g_b, h_b, b, h_a, a);
   
  h_g_z = h_g_z';
  g_z = g_z';
  z = z';

% $Id: adimat_h_mrdivide2.m 4114 2014-05-06 14:28:30Z willkomm $
