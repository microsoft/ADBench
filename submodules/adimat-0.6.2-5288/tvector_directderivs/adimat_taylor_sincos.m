% function [t_sin sinx t_cos cosx] = adimat_taylor_sincos(t_x, x)
%
% Compute taylor coefficients of sin(x) and cos(x) simultaneously.
%
% see also admTaylorFor
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function [t_sin sinx t_cos cosx] = adimat_taylor_sincos(t_x, x)
  [t_sin t_cos] = deal(t_zeros(x));
  [ndd maxOrder nel] = size(t_x);

  sinx = sin(x);
  cosx = cos(x);

  sinxr = reshape(sinx, [1 1 nel]);
  cosxr = reshape(cosx, [1 1 nel]);

  for o=1:maxOrder
    for k=1:o-1
      t_sin(:, o, :) = t_sin(:, o, :) + t_cos(:, o-k, :) .* k .* t_x(:, k, :);
      t_cos(:, o, :) = t_cos(:, o, :) - t_sin(:, o-k, :) .* k .* t_x(:, k, :);
    end
    t_sin(:, o, :) = t_sin(:, o, :) + repmat(cosxr .* o, [ndd 1 1]) .* t_x(:, o, :);
    t_cos(:, o, :) = t_cos(:, o, :) - repmat(sinxr .* o, [ndd 1 1]) .* t_x(:, o, :);
    t_sin(:, o, :) = t_sin(:, o, :) ./ o;
    t_cos(:, o, :) = t_cos(:, o, :) ./ o;
  end
end
% $Id: adimat_taylor_sincos.m 3251 2012-03-26 13:26:27Z willkomm $
