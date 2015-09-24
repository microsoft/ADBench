function display(g)
%ADDERIV/DISPLAY Print a derivative.
%
% Copyright 2001-2004 Andre Vehreschild, Institute for Scientific Computing   
%                     RWTH Aachen University
% This code is under development! Use at your own risk! Duplication,
% modification and distribution FORBIDDEN!


disp(' ');
if g.dims==1
   disp(sprintf('adderivsp: number of directional derivatives: %d', g.ndd));
   disp(' ');
   for i= 1: g.ndd
      disp(g.deriv{i});
   end
else
   disp(sprintf('adderivsp: total number of directional derivatives: %dx%d', g.ndd));
   disp(' ');
   for i= 1: g.ndd(1)
      disp(sprintf('  (%d,:)', i));
      for j= 1: g.ndd(2)
         disp(g.deriv{i,j});
      end
   end
end
disp(' ');

