% function [a_a, a_b, z] = adimat_a_mldivide(a, b, a_z)
%
% Compute adjoints a_a and a_b of z = a \ b, matrix left
% division. Also return the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012-2014 Johannes Willkomm
%
function [a_a, a_b, z] = adimat_a_mldivide(a, b, a_z)
  [m n] = size(a);
  
  if m == 1 && n == 1
    z = a \ b;
    a_b = adimat_adjred(b, a .\ a_z);
    a_a = adimat_adjred(a, a .\ -(a_z .* z));
  elseif m == n
    z = a \ b;
    a_b = a.' \ a_z;
    a_a = a.' \ -(a_z * z.');
  else
    if m > n && strcmp(admGetPref('nonSquareSystemSolve'), 'fast')
      L = a';
      Q = L*a;
      % c = L*b;
      z = a \ b;
      a_Q = Q.' \ -(a_z * z.');
      a_c = Q.' \ a_z;
      a_L = a_Q*a.' + a_c*b.';
      a_a = L.'*a_Q + a_L';
      a_b = L.'*a_c;
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
      [a_a a_b z] = a_adimat_sol_qr(a, b, a_z);
    end
  end

% $Id: adimat_a_mldivide.m 4361 2014-05-28 11:14:11Z willkomm $
  