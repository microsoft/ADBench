function [params,indices] = au_ransac(opts)
% AU_RANSAC     Ransac loop
%             OPTS = au_RANSAC('opts', NDATA, NSAMPLES);
%             au_RANSAC(OPTS)
%               OPTS.NDATA
%                   Number of points
%               OPTS.NSAMPLES
%                   Number of points to pass to the fit function
%               OPTS.MAXITERS
%                   Max #iterations
%               OPTS.THRESHOLD
%                   Outlier threshold - needed for convergence 
%                   computation.  Defaults to >= 1 so that top-hat
%                   error functions mark outliers.
%               OPTS.FIT(INDICES)
%                   A function handle which returns a vector of
%                   parameters given a minimal set of indices
%               OPTS.COMPUTE_RESIDUALS
%                   A function handle which returns a vector of
%                   parameters given a minimal set of indices
%               OPTS.OUTPUT

% awf, aug06

%% Demo if no arguments
if nargin == 0
  au_ransac_demo;
  return
end

%% Return default options if called with 'opts' as first argument
if ischar(opts) && strcmp(opts, 'opts')
  o.MAXITERS = 1000;
  o.VERBOSE = 1;
  o.THRESHOLD = 1;
  if nargin > 1
    o.NDATA = fit;
    o.NSAMPLES = compute_residuals;
  end
  params = o;
  return
end

%% Normal call.

% 1. Extract options
have_output = isfield(opts, 'output');

VERBOSE = opts.VERBOSE;  

N = opts.NDATA;
n = opts.NSAMPLES;
MAXITERS = opts.MAXITERS;
THRESHOLD = opts.THRESHOLD;
best_n_inliers = 0;

% 2. Iterate
iter = 0;
while iter < MAXITERS
  iter = iter+1;
  if VERBOSE == 2
    fprintf('iter %4d: ', iter);
  end

  % 2.1 Draw sample indices
  sample_indices = randperm(N, n);
  
  if VERBOSE == 2
    fprintf('[%3d', sample_indices(1));
    if n>1
      fprintf(' %3d', sample_indices(2:end));
    end
    fprintf('] ');
  end
  
  % 2.2 Fit model
  params = opts.fit(sample_indices);
  
  % 2.3 Compute residuals and error
  residuals = opts.compute_residuals(params, 1:N);
  err = sum(abs(residuals));

  % 2.4 Check if best so far
  n_inliers = sum(abs(residuals) < THRESHOLD);
  if n_inliers > best_n_inliers
    if have_output, opts.output(err, sample_indices, params); end
    best_n_inliers = n_inliers;
    best_indices = sample_indices;
    best_params = params;
    
    % Use #inliers to recompute iteration count
    MAXITERS = min(MAXITERS, compute_iters(n_inliers, N, n));
    if VERBOSE == 1
      fprintf('iter %4d/%-4d: inliers %3d\n', iter, MAXITERS, n_inliers);
    end
    if VERBOSE == 2
      fprintf('best ');
    end
  end
  if VERBOSE == 2
    fprintf('err = %g\n', err);
  end
  
end

params = best_params;
indices = best_indices;

%% Draw n samples from N data
% no longer needed in later matlabs
% function sample_indices = draw_samples(N,n)
% if (N > 1000) && (n*10 < N)
%   while 1
%     sample_indices = sort(round(rand(n,1) * N));
%     if ~any(diff(sample_indices) == 0)
%       break
%     end
%   end
% else
%   sample_indices = randperm(N);
%   sample_indices = sample_indices(1:n);
% end

%% compute_iters
% Compute number of iterations needed to achieve a given
% probability of finding an all-inlier sample set.  Note
% that even all-inlier sets may not give a good fit, so
% in general the quality number is set higher than needed.
function i = compute_iters(n_inliers, N,n)
quality = 1e-4;
log_quality = -9.2103;

ratio = n_inliers / N;

p = ratio^n;
if p >= 1-quality
  i = 1;
  return
end

if ratio == 0.0
  i = Inf;
  return;
end

if p < 1e-8
  l = -p - 1/2*p.^2;
else
  l = log(1.0 - p);
end
i = ceil(log_quality / l);
