% function z = adimat_mldivide(A, B)
% 
% Model MATLAB's \ operator (mldivide), for automatic differentiation.
%
% Copyright 2013 Johannes Willkomm, Fachgebiet Scientific Computing
%                     TU Darmstadt
function z = adimat_mldivide(A, B)
  if isscalar(A)
    z = B ./ A;
  else
    z = linsolve(A, B);
  end
end
% $Id: adimat_hess.m 3865 2013-09-19 15:57:49Z willkomm $
