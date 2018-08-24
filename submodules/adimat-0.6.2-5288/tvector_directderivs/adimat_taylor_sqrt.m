% function [t_sqrt sqrtx] = adimat_taylor_sqrt(t_x, x)
%
% Compute taylor coefficients of sqrt(x).
%
% see also admTaylorFor
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function [t_sqrt sqrtx] = adimat_taylor_sqrt(t_x, x)
  [ndd maxOrder nel] = size(t_x);

  sqrtx = sqrt(x);

  factor = reshape(1 ./ (2 .* sqrtx), [1 1 nel]);
  factor = repmat(factor, [ndd 1 1]);

  t_sqrt = t_zeros(x);

  for o=1:maxOrder
    for k=1:o-1
      t_sqrt(:,o,:) = t_sqrt(:,o,:) - t_sqrt(:,o-k,:) .* t_sqrt(:,k,:);
    end
    t_sqrt(:,o,:) = t_sqrt(:,o,:) + t_x(:,o,:);
    t_sqrt(:,o,:) = t_sqrt(:,o,:) .* factor;
  end

% $Id: adimat_taylor_sqrt.m 3251 2012-03-26 13:26:27Z willkomm $
