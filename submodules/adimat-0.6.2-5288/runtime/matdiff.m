% function [partial z] = matdiff(x, handle, base?)
%
% Compute derivative of matrix function z = handle(x) for square x
% using the identity [z, dZ; 0, z] = f([x, dx; 0, x]). base is the
% seed matrix. If base is not given it is set to eye(numel(x)).
%
% see also partial_funm, matdiff1
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z varargout] = matdiff(x, handle, base)
  if nargin < 3
    base = eye(numel(x));
  end
  nmoreout = nargout - 2;

  partial = zeros(size(base));
  
  funName = func2str(handle);

  ndd = size(base, 2);
  for i=1:ndd
    dx = reshape(base(:, i), size(x));
    
    [dz z varargout{1:nmoreout}] = matdiff1(dx, x, handle);
    
    partial(:, i) = dz(:);
  end

% $Id: matdiff.m 4688 2014-09-18 10:01:13Z willkomm $
