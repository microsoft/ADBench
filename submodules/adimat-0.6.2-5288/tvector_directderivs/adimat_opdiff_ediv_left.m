% function r = adimat_opdiff_ediv_left(v1, t_v2, v2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [t_res res] = adimat_opdiff_ediv_left(v1, t_v2, v2)
  [t_v2i v2i] = adimat_taylor_invert(t_v2, v2);
  [t_res res] = adimat_opdiff_emult_left(v1, t_v2i, v2i);
end  
% $Id: adimat_opdiff_ediv_left.m 3277 2012-04-18 14:03:00Z willkomm $
