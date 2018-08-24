% function [t_sinh sinhx t_cosh coshx] = adimat_taylor_sinhcosh(t_x, x)
%
% Compute taylor coefficients of sinh(x) and cosh(x) simultaneously.
%
% see also admTaylorFor
%
% Copyright 2012 Johannes Willkomm, Institute for Scientific Computing
%           RWTH Aachen University.
%
function [t_sinh sinhx t_cosh coshx] = adimat_taylor_sinhcosh(t_x, x)
  [t_sinh t_cosh] = deal(t_zeros(x));
  [ndd maxOrder nel] = size(t_x);

  sinhx = sinh(x);
  coshx = cosh(x);
  
  sinhxr = reshape(sinhx, [1 1 nel]);
  coshxr = reshape(coshx, [1 1 nel]);
  
  for o=1:maxOrder
    for k=1:o-1
      t_sinh(:, o, :) = t_sinh(:, o, :) + t_cosh(:, o-k, :) .* k .* t_x(:, k, :);
      t_cosh(:, o, :) = t_cosh(:, o, :) + t_sinh(:, o-k, :) .* k .* t_x(:, k, :);
    end
    t_sinh(:, o, :) = t_sinh(:, o, :) + repmat(coshxr .* o, [ndd 1 1]) .* t_x(:, o, :);
    t_cosh(:, o, :) = t_cosh(:, o, :) + repmat(sinhxr .* o, [ndd 1 1]) .* t_x(:, o, :);
    t_sinh(:, o, :) = t_sinh(:, o, :) ./ o;
    t_cosh(:, o, :) = t_cosh(:, o, :) ./ o;
  end
end
% $Id: adimat_taylor_sinhcosh.m 3251 2012-03-26 13:26:27Z willkomm $
