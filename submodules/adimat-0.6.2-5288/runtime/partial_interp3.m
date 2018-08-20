% function [partial z] = partial_interp3(xs,ys,zs, vs, xis,yis,zis,...)
%   compute partial interp3(xs,ys,z,s vs, xis,yis,zis,...) w.r.t. to vs
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_interp3(xs,ys,zs, vs, xis,yis,zis, varargin)
  partial = zeros([numel(xis), numel(vs)]);
  d_vs = zeros(size(vs));
  for i=1:numel(vs)
    d_vs(i) = 1;
    t = interp3(xs, ys, zs, d_vs, xis, yis, zis, varargin{:});
    partial(:,i) = t(:);
    d_vs(i) = 0;
  end
  if nargout > 1
    z = interp3(xs, ys, zs, vs, xis, yis, zis, varargin{:});
  end
% $Id: partial_interp3.m 3502 2013-01-27 23:53:38Z willkomm $
