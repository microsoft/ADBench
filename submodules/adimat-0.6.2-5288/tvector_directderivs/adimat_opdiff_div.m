% function r = adimat_opdiff_div(t_val1, val1, t_val2, val2)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function [t_res res] = adimat_opdiff_div(t_val1, val1, t_val2, val2)
  if isscalar(val2)
    [t_res res] = adimat_opdiff_ediv(t_val1, val1, t_val2, val2);
  else
    [t_res res] = adimat_opdiff_sol(adimat_opdiff_trans(t_val2), val2', ...
                                    adimat_opdiff_trans(t_val1), val1');
    t_res = adimat_opdiff_trans(t_res);
    res = res';
  end
end
% $Id: adimat_opdiff_div.m 3230 2012-03-19 16:03:21Z willkomm $
