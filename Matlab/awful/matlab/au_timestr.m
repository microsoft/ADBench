function str =  au_timestr(t, method)

% AU_TIMESTR   t is in seconds.
%               ...

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 14 Feb 03

if nargin < 2
  method = 1;
end

switch method
 case 1
  s = rem(t, 60);
  m = rem(floor(t/60), 60);
  h = floor(t/3600);

  if h > 0
    str= sprintf('%dh%02dm%04.1fs', h,m,s);
  elseif m > 0
    str = sprintf('%dm%04.1fs', m, s);
  else
    str = sprintf('%.2fsec', s);
  end
 case 2
  S = 24*3600;
  str = [datestr(t / S, 8) ' ' datestr(t / S, 16)];
end
