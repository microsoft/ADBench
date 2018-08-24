% function [g_z z] = adimat_g_mrdivide2(a, g_b, b)
%
% Compute derivative of z = a / b, matrix right division. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_mrdivide2(a, g_b, b)

  [m n] = size(b);
  
  z = a / b;

  if (admIsOctave() && m == n) || (~admIsOctave() && m >= n)
    g_z = (-z * g_b) / b;
  else
    g_z = g_adimat_sol_qr(g_b', b', g_zeros(size(a')), a')';
  end

% $Id: adimat_g_mrdivide2.m 3935 2013-10-15 16:27:52Z willkomm $
