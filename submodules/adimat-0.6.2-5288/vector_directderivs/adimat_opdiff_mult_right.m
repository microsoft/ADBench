% function d_res = adimat_opdiff_mult_right(d_val1, val1, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
function d_val1 = adimat_opdiff_mult_right(d_val1, val1, val2)
  if isscalar(val1) || isscalar(val2)
    d_val1 = adimat_opdiff_emult_right(d_val1, val1, val2);
  else
    
    [ndd m n] = size(d_val1);
    d_val1 = reshape(reshape(d_val1, [ndd.*m n]) * val2, [ndd m size(val2,2)]);
  
  end
% $Id: adimat_opdiff_mult_right.m 4355 2014-05-28 11:10:28Z willkomm $
