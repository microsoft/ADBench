% function [a_b, z] = adimat_a_mldivider(a, b, a_z)
%
% Compute adjoint a_b of z = a \ b, matrix right division. Also return
% the function result z.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright 2012-2014 Johannes Willkomm
%
function [a_b, z] = adimat_a_mldivider(a, b, a_z)
  [m n] = size(a);
  
  if m == 1 && n == 1
    z = a \ b;
    a_b = adimat_adjred(b, a .\ a_z);
  elseif m == n
    z = a \ b;
    a_b = adimat_adjred(b, a.' \ a_z);
  else
    Q = a.'*a;
    z = a \ b;
    a_b = adimat_adjred(b, a * (Q \ a_z));
  end

% $Id: adimat_a_mldivider.m 4815 2014-10-09 07:47:09Z willkomm $
  