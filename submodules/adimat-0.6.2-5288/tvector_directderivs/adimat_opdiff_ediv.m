% function r = adimat_opdiff_ediv(t_v1, v1, t_v2, v2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [t_res res] = adimat_opdiff_ediv(t_v1, v1, t_v2, v2)
  [t_v2i v2i] = adimat_taylor_invert(t_v2, v2);
  [t_res res] = adimat_opdiff_emult(t_v1, v1, t_v2i, v2i);
end  
% $Id: adimat_opdiff_ediv.m 3226 2012-03-18 12:00:04Z willkomm $
