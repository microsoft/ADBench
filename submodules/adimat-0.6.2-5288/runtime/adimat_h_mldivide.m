% function [h_g_z g_z z] = adimat_h_mldivide(h_g_a, g_a, h_a, a, h_g_b, g_b, h_b, b)
%
% Compute first and second order derivative of z = a \ b, matrix left
% division. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (C) 2013,2014 Johannes Willkomm
%
function [h_g_z g_z z] = adimat_h_mldivide(h_g_a, g_a, h_a, a, h_g_b, g_b, h_b, b)

  [m n] = size(a);
  
  z = a \ b;

  if (admIsOctave() && m == n) || (~admIsOctave() && m <= n)
    g_z = a \ (g_b - g_a * z);
    h_z = a \ (h_b - h_a * z);
    h_g_z = a \ (h_g_b - (h_g_a * z + g_a * h_z) - h_a * g_z);
  else  
    [h_g_z g_z] = h_adimat_sol_qr(h_g_a, g_a, h_a, a, h_g_b, g_b, h_b, b);
  end

% $Id: adimat_h_mldivide.m 4354 2014-05-25 16:26:47Z willkomm $
