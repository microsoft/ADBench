% function d_res = adimat_opdiff_sol_left(val1, d_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
function d_val2 = adimat_opdiff_sol_left(val1, d_val2, val2)
  if isscalar(val1) || isscalar(val2)
    d_val2 = adimat_opdiff_ediv_right(d_val2, val2, val1);
  else
    d_val2 = adimat_mldivide_vd(val1, d_val2);
  end
end
% $Id: adimat_opdiff_sol_left.m 4355 2014-05-28 11:10:28Z willkomm $
