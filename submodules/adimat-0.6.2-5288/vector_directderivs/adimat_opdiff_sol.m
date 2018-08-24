% function d_res = adimat_opdiff_sol(d_val1, val1, d_val2, val2)
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
function d_val1 = adimat_opdiff_sol(d_val1, val1, d_val2, val2)
  if isscalar(val1) || isscalar(val2)
    d_val1 = adimat_opdiff_ediv(d_val2, val2, d_val1, val1);
  else
    [ndd m n] = size(d_val1);
    [m p] = size(val2);
    res = val1 \ val2;
    if m == n || (~admIsOctave() && m <= n)
      % g_z = a \ (g_b - g_a * z);
      RHS = d_val2 - adimat_opdiff_mult_right(d_val1, val1, res);
      d_val1 = adimat_mldivide_vd(val1, RHS);
    elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      % g_z = (a'*a) \ (g_a'*(b - a*z) + a'*(g_b - g_a*z));
      RHS = adimat_opdiff_mult_right(adimat_opdiff_trans(d_val1), val1', val2 - val1*res) ...
            + adimat_opdiff_mult_left(val1', d_val2 - adimat_opdiff_mult_right(d_val1, val1, res), val2);
      d_val1 = adimat_mldivide_vd(val1'*val1, RHS);
    else
      d_val1 = d_adimat_sol_qr(d_val1, val1, d_val2, val2);
    end
  end
end
% $Id: adimat_opdiff_sol.m 4364 2014-05-28 12:24:13Z willkomm $
