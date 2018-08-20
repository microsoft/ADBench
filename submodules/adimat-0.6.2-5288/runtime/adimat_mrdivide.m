% function z = adimat_mrdivide(A, B)
% 
% Model MATLAB's / operator (mrdivide), for automatic differentiation.
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function z = adimat_mrdivide(A, B)
  if isscalar(B)
    z = A ./ B;
  else
    z = linsolve(B', A')';
  end
end
% $Id: adimat_hess.m 3865 2013-09-19 15:57:49Z willkomm $
