% function [h_z g_z z] = adimat_h_mrdivide(h_g_a, g_a, h_a, a, h_g_b, g_b, h_b, b)
%
% Compute first and second order derivative of z = a / b, matrix right
% division. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2013,2014 Johannes Willkomm
%
function [h_g_z g_z z] = adimat_h_mrdivide(h_g_a, g_a, h_a, a, h_g_b, g_b, h_b, b)

  [h_g_z g_z z] = adimat_h_mldivide(h_g_b', g_b', h_b', b', h_g_a', g_a', h_a', a');

  h_g_z = h_g_z';
  g_z = g_z';
  z = z';
  
% $Id: adimat_h_mrdivide.m 4106 2014-05-05 08:58:11Z willkomm $
