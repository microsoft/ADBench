% function d_res = adimat_opdiff_esol_right(d_val1, val1, val2)
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_res = adimat_opdiff_esol_right(d_val1, val1, val2)
  d_res = adimat_opdiff_ediv_left(val2, d_val1, val1);
% $Id: adimat_opdiff_esol_right.m 3232 2012-03-19 21:22:33Z willkomm $
