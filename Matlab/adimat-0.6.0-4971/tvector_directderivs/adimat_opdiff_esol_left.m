% function r = adimat_opdiff_esol_left(val1, g_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_esol_left(val1, t_val2, val2)
  t_res = adimat_opdiff_ediv_right(t_val2, val2, val1);
% $Id: adimat_opdiff_esol_left.m 3230 2012-03-19 16:03:21Z willkomm $
