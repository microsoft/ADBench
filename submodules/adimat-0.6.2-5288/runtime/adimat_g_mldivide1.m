% function [g_z z] = adimat_g_mldivide1(g_a, a, b)
%
% Compute derivative of z = a \ b, matrix left division. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2013,2014 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [g_z z] = adimat_g_mldivide1(g_a, a, b)
  
  [m n] = size(a);
  
  z = a \ b;

  if m == n || (~admIsOctave() && m < n)
    g_z = a \ (-g_a * z);
  elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
    % rhs = g_a'*(b - a*z) - a'*(g_a*z);
    rhs = ((b - a*z)'*g_a)' - a'*(g_a*z);
    g_z = (a'*a) \ rhs;
  else
    g_z = g_adimat_sol_qr(g_a, a, g_zeros(size(b)), b);
  end

% $Id: adimat_g_mldivide1.m 4557 2014-06-15 18:20:41Z willkomm $
