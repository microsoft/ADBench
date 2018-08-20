% function t_res = adimat_opdiff_trans(t_val, val)
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function t_res = adimat_opdiff_trans(t_val, val)
  t_res = permute(conj(t_val), [1 2 4 3]);
% $Id: adimat_opdiff_trans.m 3230 2012-03-19 16:03:21Z willkomm $
