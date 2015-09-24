function g=transpose(g)
%ADDERIV/TRANSPOSE Transpose the derivative
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!

  g.deriv = cellfun(@transpose, g.deriv, 'uniformoutput', false);
