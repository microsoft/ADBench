% function z = adimat_sol_qr(a, b)
% 
% Solve linear system a*x = b for x by solving (a'*a)*x=a'*b which is
% always a square system, for automatic differentiation.
%
% Copyright 2013,2014 Johannes Willkomm
%
function z = adimat_sol_ata(a, b)
  L = a';
  z = linsolve(L*a, L*b);
% $Id: adimat_sol_ata.m 4813 2014-10-09 07:33:03Z willkomm $
