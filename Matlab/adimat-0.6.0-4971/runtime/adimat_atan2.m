% function t = adimat_atan2(y, x)
%
% ADiMat replacement function for atan2
%
% Copyright (C) 2015 Johannes Willkomm
function t = adimat_atan2(y, x)
  xl0 = x < 0;
  yl0 = y < 0;
  xe0 = x == 0;
  ye0 = y == 0;
  yg0 = ~yl0 & ~ye0;
  t = x + y;
  t(~xe0) = atan(y(~xe0) ./ x(~xe0));
  t(xe0 & yl0) = - atan(x(xe0 & yl0) ./ y(xe0 & yl0)) - pi/2;
  t(xe0 & yg0) = pi/2 - atan(x(xe0 & yg0) ./ y(xe0 & yg0));
  t(xl0 & yl0) = t(xl0 & yl0) - pi;
  t(xl0 & yg0) = t(xl0 & yg0) + pi;
  t(xe0 & ye0) = 0;
end
% $Id: adimat_atan2.m 4947 2015-03-02 10:46:27Z willkomm $
