% function [a_a, z] = adimat_a_mldividel(a, b, a_z)
%
% Compute adjoint a_a of z = a \ b, matrix right division. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012-2014 Johannes Willkomm
%
function [a_a, z] = adimat_a_mldividel(a, b, a_z)
  [m n] = size(a);

  if m == 1 && n == 1
    z = a \ b;
    a_a = adimat_adjred(a, a .\ -(a_z .* z));
  elseif m == n
    z = a \ b;
    a_a = adimat_adjred(a, a.' \ -(a_z * z.'));
  else
    if m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      Q = a.'*a;
      z = a \ b;
      a_a = adimat_adjred(a, (Q \ (a_z *(b.' - z.' * a.'))).');
      a_a = a_a + adimat_adjred(a, a*(Q \ -a_z*z.'));
    else
      if m < n
        if ~admIsOctave()
          warning('adimat:rev:mldivide:underdetermined_not_supported', ...
                  ['The differentiation of mldivide (\\) in RM with m(=%d) < n(=%d)'...
                   '(underdetermined LS) is not supported in MATLAB.'...
                   ' Consider using adimat_sol_qr in your code instead.'], ...
                  m, n);
        end
      end
      [a_a, ~, z] = a_adimat_sol_qr(a, b, a_z);
    end
  end

% $Id: adimat_a_mldividel.m 4147 2014-05-11 11:25:59Z willkomm $
  