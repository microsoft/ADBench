% function d_res = adimat_opdiff_trans(d_val, val)
%
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_res = adimat_opdiff_trans(d_val, ~)
  d_res = permute(adimat_diff_conj(d_val), [1 3 2]);
end   
% $Id: adimat_opdiff_trans.m 4355 2014-05-28 11:10:28Z willkomm $
