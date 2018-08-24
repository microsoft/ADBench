% function r = adimat_opdiff_esol_right(t_val1, val1, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_esol_right(t_val1, val1, val2)
  t_res = adimat_opdiff_ediv_left(val2, t_val1, val1);
% $Id: adimat_opdiff_esol_right.m 3230 2012-03-19 16:03:21Z willkomm $
