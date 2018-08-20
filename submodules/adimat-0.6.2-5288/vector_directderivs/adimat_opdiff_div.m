% function r = adimat_opdiff_div(d_val1, val1, d_val2, val2)
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2010-2013 Johannes Willkomm, Institute for Scientific Computing   
%                     TU Darmstadt
function d_res = adimat_opdiff_div(d_val1, val1, d_val2, val2)
  szv2 = size(val2);
  if isscalar(val2) || (isscalar(val1) && length(szv2) > 2)
    d_res = adimat_opdiff_ediv(d_val1, val1, d_val2, val2);
  else
    m = szv2(1);
    n = szv2(2);
    res = val1 / val2;
    if (admIsOctave() && m == n) || (~admIsOctave() && m >= n)
      ndd = size(d_val1, 1);
      szv1 = size(val1);
      d_res = d_zeros(res);
      for d=1:ndd
        dd = ( reshape(d_val1(d,:), szv1) - res * reshape(d_val2(d,:), szv2) ) / val2;
        d_res(d, :) = dd(:).';
      end
    else
      d_res = d_adimat_sol_qr(adimat_opdiff_trans(d_val2, val2), val2', ...
                              adimat_opdiff_trans(d_val1, val1), val1');
      d_res = adimat_opdiff_trans(d_res, res.');
    end
  end
end
% $Id: adimat_opdiff_div.m 3935 2013-10-15 16:27:52Z willkomm $
