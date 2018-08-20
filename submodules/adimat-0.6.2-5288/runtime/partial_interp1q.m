% function [partial z] = partial_interp1(xs, ys, xis, varargin)
%   compute partial interp1(xs, ys, xis, ...) w.r.t. to ys
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_interp1(xs, ys, xis, varargin)
  partial = zeros([numel(xis).*size(ys, 2), numel(ys)]);
  d_ys = zeros(size(ys));
  for i=1:numel(ys)
    d_ys(i) = 1;
    t = interp1(xs, d_ys, xis, varargin{:});
    partial(:,i) = t(:);
    d_ys(i) = 0;
  end
  if nargout > 1
    z = interp1(xs, ys, xis, varargin{:});
  end
% $Id: partial_interp1q.m 3502 2013-01-27 23:53:38Z willkomm $
