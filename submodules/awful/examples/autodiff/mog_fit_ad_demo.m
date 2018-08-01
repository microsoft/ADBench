function perf_data = mog_fit_ad_demo

% * autodiff version *

% Fit a mix of Gaussian to some points by nonlinear minimization of
% -log(likelihood)

% The likelihood is defined in ad_logmog
%%
if 2
  mog = mog_gallery(3);
  x = mog_draw(mog, 1000);
else
  x = rand_donut(20,20,1000);
  x = x / 40 + .5;
end

disp('fit_ad_demo');
clf
awf_scatter(x,'k.')
axis([0 1 0 1])
drawnow

K = ad_logmog_K;

GX = 1;

fprintf('fit em:')
tic
[emout, mog_init] = mog_fit(x, K, GX);
t = toc;
perf_data.em.E = emout.E;
perf_data.em.time = t;
fprintf(', %g sec\n', t);
perf_data.em.iters = emout.iters;
h2 = mog_ellipses(emout.mog);
set(h2, 'color', [1 0 0]*.7)

fprintf('fit ad:')
adout = mog_fit_ad(x, GX, mog_init);
h1 = mog_ellipses(adout.ls.mog);
set(h1, 'color', [0 1 0]*.7, 'linestyle', '--');
drawnow
for n=fieldnames(adout)', 
  perf_data.(n{1}) = adout.(n{1});
end
h2 = mog_ellipses(emout.mog);
set(h2, 'color', [1 0 0]*.7)

set([h1 h2], 'linewidth', 4)
legend([h2(1) h1(1)], ...
  sprintf('EM: %.3f', -perf_data.em.E), ...
  sprintf('2ndOrder: %.3f', -perf_data.ls.E))
