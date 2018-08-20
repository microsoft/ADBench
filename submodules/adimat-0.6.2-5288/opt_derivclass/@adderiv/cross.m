% @adderiv/cross
% function obj = cross(a, b, dim)
%
% Compute cross product.
%
% This file is part of the ADiMat runtime environment.
%
% Copyright (c) 2016 Johannes Willkomm
function obj = cross(a, b, dim)
  if nargin < 3
    dim = find(size(a) == 3);
  end
  obj = call(@cross, a, b, dim);
end
