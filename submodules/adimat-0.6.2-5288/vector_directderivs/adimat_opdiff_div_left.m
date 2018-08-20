% function d_res = adimat_opdiff_div_left(val1, g_val2, val2)
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function d_res = adimat_opdiff_div_left(val1, d_val2, val2)
  szv2 = size(val2);
  if isscalar(val2) || (isscalar(val1) && length(szv2) > 2)
    d_res = adimat_opdiff_ediv_left(val1, d_val2, val2);
  else
    m = szv2(1);
    n = szv2(2);
    res = val1 / val2;
    ndd = size(d_val2, 1);
    d_res = d_zeros(res);
    if (admIsOctave() && m == n) || (~admIsOctave() && m >= n)
      for d=1:ndd
        dd = - res * reshape(d_val2(d,:), szv2) / val2;
        d_res(d,:) = dd(:).';
      end
    else
      d_res = d_adimat_sol_qr1(adimat_opdiff_trans(d_val2, val2), val2', val1');
      d_res = adimat_opdiff_trans(d_res, res.');
    end
  end
end
% $Id: adimat_opdiff_div_left.m 3935 2013-10-15 16:27:52Z willkomm $
