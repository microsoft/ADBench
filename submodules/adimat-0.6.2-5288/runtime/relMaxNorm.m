function [r a m1 m2] = relMaxNorm(M1, M2, p)
  if nargin < 3, p = 2; end
  if p == 2
    M1 = full(M1);
    M2 = full(M2);
  end
  if length(size(M1)) > 2
    M1 = M1(:);
    M2 = M2(:);
  end
  m1 = norm(M1, p);
  m2 = norm(M2, p);
  divi = max(m1, m2);
  a = norm(M1 - M2, p);
  if divi ~= 0
    r = a ./ divi;
  else
    r = a;
  end
% $Id: relMaxNorm.m 4439 2014-06-04 20:11:20Z willkomm $
