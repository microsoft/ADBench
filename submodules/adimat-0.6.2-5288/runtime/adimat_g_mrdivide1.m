% function [g_z z] = adimat_g_mrdivide1(g_a, a, b)
%
% Compute derivative of z = a / b, matrix right division, with b
% constant. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_mrdivide1(g_a, a, b)

  [m n] = size(b);
  
  z = a / b;

  if isscalar(b)
    g_z = g_a ./ b;
  else
    if (admIsOctave() && m == n) || (~admIsOctave() && m >= n)
      g_z = g_a / b;
    else
      g_z = g_adimat_sol_qr(g_zeros(size(b')), b', g_a', a')';
    end
  end
  
% $Id: adimat_g_mrdivide1.m 3986 2013-12-27 16:39:06Z willkomm $
