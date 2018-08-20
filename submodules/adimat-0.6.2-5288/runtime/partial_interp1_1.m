% function [partial z] = partial_interp1_1(xs, ys, xis, varargin)
%   compute partial interp1(xs, ys, xis, ...) w.r.t. to xs
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_interp1_1(xs, ys, xis, method, extrap)
  if nargin < 4
    method = 'linear';
  end
  if nargin < 5
    extrap = nan();
  end
  if isnan(extrap)
    extrapder = nan();
  elseif ischar(extrap)
    extrapder = nan();
  else
    extrapder = 0;
  end
  partial = zeros([numel(xis), numel(xs)]);
  switch method
   case 'nearest'
    % partial is zero
   case 'linear'
    dxs = diff(xs);
    dys = diff(ys);
    for i=1:numel(xis)
      w = find(xs <= xis(i));
      w = w(end);
      if w == length(xs)
        if xis(i) == xs(end)
          partial(i, w) = extrapder;
        else % xis(i) > xs(end)
          partial(i, :) = extrapder;
        end
      else
        partial(i, w) = (xis(i) - xs(w)) * dys(w) / dxs(w).^2 ...
            - dys(w) ./ dxs(w);
        partial(i, w+1) = -(xis(i) - xs(w)) * dys(w) / dxs(w).^2;
      end
    end
   otherwise
    warning('adimat:partial_interp1:unsupportedMethod', ['The method ' ...
                        '"%s" is not supported when computing the derivative of interp1 w.r.t. the ' ...
                        'input X, returning a zero partial derivative'], method);
  end
  if ~isvector(ys)
    [N nel] = size(ys);
    partial = repmat(partial, [nel, 1]);
  end
  if nargout > 1
    z = interp1(xs, ys, xis, method, extrap);
  end
% $Id: partial_interp1_1.m 3657 2013-05-22 16:39:59Z willkomm $
