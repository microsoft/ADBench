% function [t, y_obj] = ode15s(func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode15s(func, ts, y0)
  [t, y_obj] = ode_generic(@ode15s, func, ts, y0);
