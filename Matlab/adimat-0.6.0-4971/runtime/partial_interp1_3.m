% function [partial z] = partial_interp1_3(xs, ys, xis, varargin)
%
% Compute partial interp1(xs, ys, xis, ...) w.r.t. to xis
%
% This file is part of the ADiMat runtime environment
%
% Copyright 2013 Johannes Willkomm, Institute for Scientific Computing
%                     TU Darmstadt
function [partial z] = partial_interp1_3(xs, ys, xis, method, extrap)
  if nargin < 4
    method = 'linear';
  end
  if nargin < 5
    extrap = nan();
  end
  [N nel] = size(ys);
  partial = zeros([numel(xis).*nel, numel(xis)]);
  switch method
   case 'nearest'
    % partial is zero
   case {'linear', 'spline', 'cubic', 'pchip', 'v5cubic'}
    pp = interp1(xs, ys, method, 'pp');
    dpp = adimat_ppder(pp);
    dppvals = ppval(dpp, xis);
    if isvector(ys)
      partial = diag(dppvals);
    else
      splits = cell(length(size(ys)),1);
      splits{1} = numel(xis);
      for i=2:length(size(ys))
        splits{i} = ones(size(ys, i), 1);
      end
      cells = mat2cell(dppvals, splits{:});
      cells = cellfun(@diag, cells, 'uniformoutput', false);
      partial = cat(1, cells{:});
    end
   otherwise
    warning('adimat:partial_interp1:unsupportedMethod', ['The method ' ...
                        '"%s" is not supported when computing the derivative of interp1 w.r.t. the ' ...
                        'input XI, returning a zero partial derivative'], method);
    % partial is zero
  end
  if nargout > 1
    z = interp1(xs, ys, xis, method, extrap);
  end
% $Id: partial_interp1_3.m 3657 2013-05-22 16:39:59Z willkomm $
