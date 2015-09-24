% function d_res = adimat_opdiff_esol(d_v1, v1, d_v2, v2)
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_res = adimat_opdiff_esol(d_v1, v1, d_v2, v2)
  d_res = adimat_opdiff_ediv(d_v2, v2, d_v1, v1);
% $Id: adimat_opdiff_esol.m 3232 2012-03-19 21:22:33Z willkomm $
