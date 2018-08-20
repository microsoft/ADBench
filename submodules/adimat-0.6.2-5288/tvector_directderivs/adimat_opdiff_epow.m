% function t_res = adimat_opdiff_epow(g_val1, val1, g_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [t_res res] = adimat_opdiff_epow(t_val1, val1, t_val2, val2)
  % compute a.^x as exp(x .* log(a))
  [t_log1, log1] = adimat_diff_log(t_val1, val1);
  [t_p, p] = adimat_opdiff_emult(t_val2, val2, t_log1, log1);
  [t_res res] = adimat_diff_exp(t_p, p);
% $Id: adimat_opdiff_epow.m 3277 2012-04-18 14:03:00Z willkomm $
