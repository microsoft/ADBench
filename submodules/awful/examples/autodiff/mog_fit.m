function [out, moginit] =  mog_fit(X, n, GX)

% MOG_FIT       Fit mixture of Gaussians to X vi E-M
%               MOG_FIT(X, N_centres)

% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 05 Nov 01

if nargin == 0
  mog_fit_ad_demo;
  return
end

% 0. Set constants
if nargin < 3
  GX = 1;
end

d = size(X,2);

npts = size(X,1);

MeanX = mean(X);
CovX = cov(X);
[V,D] = eig(CovX);
sqrtCovX = V * sqrt(D);
I = eye(d);
lambda = 1e-5;

% 0. Choose random cluster centres
colour_list = {[1 0 0], [0 0 1], [0 .6 0]};
for i=n:-1:1
  C = MeanX' + sqrtCovX * randn(d,1);
  mog(i).mean = C; %#ok<*AGROW>
  mog(i).covariance = CovX + lambda*I;
  mog(i).colour = colour_list{rem(i-1, length(colour_list)) + 1};
end

if npts < 200
  MARKERSIZE = 1;
else
  MARKERSIZE = .1;
end

old_w = zeros(npts,n);
w = ones(npts,n);
for count=1:1000

  if count == 3
    moginit = mog;
  end
  
  % 1. Draw X
  if GX
    if GX > 1, subplot(121), end
    cla
    set(plot(X(:,1), X(:,2), 'k.'), 'markersize', MARKERSIZE)
    hold on

    mog_ellipses(mog);
    axis([-.3 1.3 -.3 1.3])
    drawnow
    if count == 1
    end
  end

  % 1. Assign weights
  w = zeros(npts, n);
  for i=1:n
    C = mog(i).mean;
    CovC = mog(i).covariance;
    if min(eig(CovC)) < 1e-8
      fprintf('iter %3d, kill %d\n', count, i);
      if 0
        % Essentially a restart -- any points which have
        % P < 1e-20 on the other Gaussians will be taken by this
        % new one.
        w(:,i) = 1e-20;
      else
        % Grab bottom 25% of points
        w(:,i) = nan;
      end
    else
      w(:,i) = mvnpdf(X, C', CovC);
    end
  end

  % Fill in weights for the tiny Gaussians so they get moved on
  w_isnan = find(isnan(w));
    
  w(w_isnan) = rand(size(w_isnan)) .* percentile(w(isfinite(w) & (w > 0)), 5);

  w = w ./ repmat(sum(w,2), 1, n);
  
  mog_w = sum(w,1)/sum(w(:));

  % fprintf('%g ', norm(old_w(:) - w(:)));
  if norm(old_w(:) - w(:))/n < 1e-7
    % fprintf('weights not changing... iters %d, error = %g, done\n', count, sum((w(:))));
    break
  end
  old_w = w;


  if GX > 1
    subplot(122)
    plot(w(:,1:end-1));

    axis([0 npts -0.1 1.1]);
  end
  % 2. Fit Gaussians
  for i=1:n
    wi = w(:,i);
    sumw = sum(wi);
    W = wi(:,ones(1,d));
    C = sum(X.*W)' / sumw;
    tx = X - repmat(C', npts, 1);
    V = (tx .* W)' * tx / sumw;
    mog(i).mean = C; 
    mog(i).covariance = (V+V')/2 + lambda*I;
    mog(i).weight = mog_w(i);

    if GX > 2
      subplot(121)
      set(plot(C(1,:), C(2,:), 'b+'), 'color', mog(i).colour, 'markersize', 34);
      hold on
      scat = @(x, s) plot(x(:,1), x(:,2), s);
      scat(X(w(:,1) < w(:,2), :), 'r.');
      scat(X(w(:,1) > w(:,2), :), 'b.');
      scat(X(w(:,1) == w(:,2), :), 'k.');
      subplot(122)
      % plot(tx)
    end
  end
  if GX,
    drawnow
  end
end
E = -sum(log(mog_pdf(mog, X) * (2*pi))) / npts;
fprintf('iter %3d, pdf = %g', count, E);
out.iters = count;
out.E = E;
out.mog = mog;
