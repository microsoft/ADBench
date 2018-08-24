% function [dz z] = matdiff1(dx, x, handle)
%
% see also matdiff, partial_funm
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [dz z varargout] = matdiff1(dx, x, handle)
  n = size(x, 1);
  zx = zeros(size(x));
  nmoreout = nargout - 2;
  
  newx = [x, dx
          zx, x];
  
  [newz varargout{1:nmoreout}] = handle(newx);

  z = newz(1:n, 1:n);
  dz = newz(1:n, n+1:2.*n);

% $Id: matdiff1.m 4688 2014-09-18 10:01:13Z willkomm $
