% function r = adimat_opdiff_esol(t_v1, v1, t_v2, v2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_esol(t_v1, v1, t_v2, v2)
  t_res = adimat_opdiff_ediv(t_v2, v2, t_v1, v1);
% $Id: adimat_opdiff_esol.m 3230 2012-03-19 16:03:21Z willkomm $
