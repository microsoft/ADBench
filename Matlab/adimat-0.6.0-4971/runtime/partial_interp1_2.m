% function [partial z] = partial_interp1_2(xs, ys, xis, varargin)
%   compute partial interp1(xs, ys, xis, ...) w.r.t. to ys
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_interp1_2(xs, ys, xis, varargin)
  if isvector(ys)
    nel = 1;
  else
    [N nel] = size(ys);
  end
  d_ys = zeros(size(xs));
  partial = zeros([numel(xis), numel(xs)]);
  for i=1:numel(xs)
    d_ys(i) = 1;
    t = interp1(xs, d_ys, xis, varargin{:});
    partial(:,i) = t(:);
    d_ys(i) = 0;
  end
  if nel > 1
    ps = {partial};
    ps = repmat(ps, [nel, 1]);
    partial = blkdiag(ps{:});
  end
  if nargout > 1
    z = interp1(xs, ys, xis, varargin{:});
  end
% $Id: partial_interp1_2.m 3657 2013-05-22 16:39:59Z willkomm $
