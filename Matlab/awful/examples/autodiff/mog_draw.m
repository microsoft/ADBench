function x = mog_draw(mog, N)

% MOG_DRAW      Draw N points from a mixture of Gaussians
%               ...

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 05 Nov 01

n = length(mog);
dim = length(mog(1).mean);

weights = cat(1, mog.weight);

if sum(weights) ~= 1
  error
end

which_gaussian = floor(interp1([0 ; cumsum(weights(:))], [1:(n+1)]', rand(N,1), '*linear'));

x = zeros(N, dim);
for i=1:n
  out_point_indices = find(which_gaussian == i);
  ni = length(out_point_indices);
  
  [V, D] = eig(mog(i).covariance);
  
  xi = randn(ni, dim);   % Draw from isotropic Gaussian
  xi = xi * D * V + repmat(mog(i).mean, ni, 1);

  x(out_point_indices, :) = xi;
end
