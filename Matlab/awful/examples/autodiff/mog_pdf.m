function p = mog_pdf(mog, x)

% MOG_PDF       Evaluate probability density at x
%               x nxd is one point per row

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 07 Nov 01

[n,d] = size(x);

p = 0;
for k=1:length(mog)
  C = mog(k).mean(:);
  V = mog(k).covariance;
  dx = x - repmat(C', n, 1);
  m = sum((dx * inv(V)) .* dx, 2);
  pk = 1/sqrt(det(V)) * exp(-m/2);
  p = p + mog(k).weight * pk;
end
p = p / (2*pi)^(d/2);
