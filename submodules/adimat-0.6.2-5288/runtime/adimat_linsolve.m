% function [S] = adimat_mldivide(A, B)
% 
% Model MATLAB's linsolve function, for automatic differentiation.
%
% Copyright 2014 Johannes Willkomm
%
function [S] = adimat_linsolve(A, B, opts)

  [m n] = size(A);
  
  if nargin < 3
    opts = struct;
    if m ~= n
      opts.RECT = true;
    end
  end
  
  if isscalar(A)
    S = B ./ A;
  elseif m == n
    S = linsolve(A, B, opts);
  elseif m < n
    if strcmp(admGetPref('nonSquareSystemSolveUnder'), 'fast')
      S = adimat_sol_ata(A, B);
    else
      S = adimat_sol_qr(A, B);
    end
  else
    if strcmp(admGetPref('nonSquareSystemSolveOver'), 'fast')
      S = adimat_sol_ata(A, B);
    else
      S = adimat_sol_qr(A, B);
    end
  end
  
end
% $Id: adimat_hess.m 3865 2013-09-19 15:57:49Z willkomm $
