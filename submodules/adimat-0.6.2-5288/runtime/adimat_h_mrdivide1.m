% function [h_z g_z z] = adimat_h_mrdivide1(h_a, g_a, a, h_b, b)
%
% Compute first and second order derivative of z = a / b, matrix right
% division, with b constant. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2013,2014 Johannes Willkomm
%
function [h_g_z g_z z] = adimat_h_mrdivide1(h_g_a, g_a, h_a, a, h_b, b)

  [h_g_z g_z z] = adimat_h_mldivide2(h_b', b', h_g_a', g_a', h_a', a');
   
  h_g_z = h_g_z';
  g_z = g_z';
  z = z';
  
% $Id: adimat_h_mrdivide1.m 4114 2014-05-06 14:28:30Z willkomm $
