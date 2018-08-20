% function d_res = adimat_opdiff_mult(g_val1, val1, g_val2, val2)
%
% Copyright 2014 Johannes Willkomm
% Copyright 2010-2012 Johannes Willkomm, Institute for Scientific Computing   
%                     RWTH Aachen University
%
% This file is part of the ADiMat runtime environment
%
function d_val1 = adimat_opdiff_mult(d_val1, val1, d_val2, val2)
  if isscalar(val1) || isscalar(val2)
    d_val1 = adimat_opdiff_emult(d_val1, val1, d_val2, val2);
  else
    
    d_val1 = adimat_opdiff_mult_right(d_val1, val1, val2) ...
             + adimat_opdiff_mult_left(val1, d_val2, val2);
    
  end

% $Id: adimat_opdiff_mult.m 4355 2014-05-28 11:10:28Z willkomm $
