% function d_res = adimat_opdiff_emult_left(val1, d_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val2 = adimat_opdiff_emult_left(val1, d_val2, ~)
  d_val2 = bsxfun(@times, reshape(full(val1), [1 size(val1)]), d_val2);
% $Id: adimat_opdiff_emult_left.m 4963 2015-03-03 11:56:24Z willkomm $
