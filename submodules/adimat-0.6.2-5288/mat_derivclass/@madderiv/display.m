function display(g)
%MADDERIV/DISPLAY Print a derivative.
%
% Copyright 2001-2005 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


disp(' ');
disp(sprintf('madderiv: derivative consists of %dx%d directional derivatives each of size %dx%d', g.ndd(1), g.ndd(2), g.sz(1), g.sz(2)));
disp(' ');
disp(g.deriv);
disp(' ');

