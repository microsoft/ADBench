% function d_res = adimat_opdiff_sol_right(d_val1, val1, val2)
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
function d_val1 = adimat_opdiff_sol_right(d_val1, val1, val2)
  if isscalar(val1) || isscalar(val2)
    d_val1 = adimat_opdiff_ediv_left(val2, d_val1, val1);
  else
    [ndd m n] = size(d_val1);
    res = val1 \ val2;
    if m == n || (~admIsOctave() && m <= n)
      d_val1 = adimat_mldivide_vd(-val1, adimat_opdiff_mult_right(d_val1, val1, res));
    elseif m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      RHS = adimat_opdiff_mult_right(adimat_opdiff_trans(d_val1), val1', val2 - val1*res) ...
            + adimat_opdiff_mult_left(-val1', adimat_opdiff_mult_right(d_val1, val1, res), val2);
      d_val1 = adimat_mldivide_vd(val1'*val1, RHS);
    else
      d_val1 = d_adimat_sol_qr1(d_val1, val1, val2);
    end
  end
end
% $Id: adimat_opdiff_sol_right.m 4365 2014-05-28 12:26:26Z willkomm $
