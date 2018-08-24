% function t_res = adimat_opdiff_epow_left(val1, t_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_epow_left(val1, t_val2, val2)
  % compute a.^x as exp(x .* log(a))
  [t_p, p] = adimat_opdiff_emult_left(log(val1), t_val2, val2);
  t_res = adimat_diff_exp(t_p, p);
end
% $Id: adimat_opdiff_epow_left.m 3230 2012-03-19 16:03:21Z willkomm $
