% function z = adimat_sol_qr(a, b)
% 
% Solve linear system a*x = b for x by QR decomposition, for automatic
% differentiation.
%
% Copyright 2013,2014 Johannes Willkomm
%
function z = adimat_sol_qr(a, b)
  [m n] = size(a);
  if m < n
    [q r] = qr(a');
    r1 = r(1:m,:);
    t = linsolve(r1, b, struct('UT', true, 'TRANSA', true));
    z = q * [t
             zeros(n-m, size(b, 2))];
  else
    [q r] = qr(a);
    q1 = q(:, 1:n);
    r1 = r(1:n,:);
    z = linsolve(r1, q1' * b, struct('UT', true));
  end
% $Id: adimat_sol_qr.m 4166 2014-05-13 08:27:58Z willkomm $
