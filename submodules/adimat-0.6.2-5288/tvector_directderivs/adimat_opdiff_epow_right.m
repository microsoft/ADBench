% function r = adimat_opdiff_epow_right(t_val1, val1, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_epow_right(t_val1, val1, val2)
  % compute a.^x as exp(x .* log(a))
  [t_log1, log1] = adimat_diff_log(t_val1, val1);
  [t_p, p] = adimat_opdiff_emult_left(val2, t_log1, log1);
  t_res = adimat_diff_exp(t_p, p);
end
% $Id: adimat_opdiff_epow_right.m 3230 2012-03-19 16:03:21Z willkomm $
