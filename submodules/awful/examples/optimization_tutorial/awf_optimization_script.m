
%% Setup
clear
clf
clc
xrange = linspace(0,1);
yrange = linspace(0,7);
z_camel = .8 + (3 - xrange).^2 .* exp(-(xrange-1).^2/20);
z1 = @(x) .8 + (3 - 20*x).^2 .* (.2 + .8*exp(-1e4*x.^2)) + 20*exp(-x*10);
z2 = @(x, y) (y*.5 - 16*x.^2 + 16*x - 5).^2 + y/2
z = @(x,y) z1(x) + 10*z2(x,y)
lz = @(x,y) (log(z(x,y)) - 2.5)*30;

x_init = 0.2;
y_init = 3;
y0 = y_init;
f = @(x) z(x, y_init);
x0 = fminbnd(f, 0, 1);

% 2D contour plot
clf
[xx,yy] = meshgrid(xrange,yrange);

zz = z(xx,yy);
lzz = lz(xx,yy);
contour(xx, yy, zz, [.7:.01:.73 .78:.02:1 1:.09:5].^4)
set(findobj(gca, 'type', 'hggroup'), 'linewidth', 2)
xlabel('x')
ylabel('y')
colormap(jet)
hold on

styles = {'linewidth', 2};
plot(x0, y_init, 'ko', styles{:}, 'markersize', 20)
plot(x0, y_init, 'k.', 'markersize', 20)

%% a 3d view...
clf
[xxs,yys] = meshgrid(xrange(1:2:end),yrange(1:4:end));
surf(xxs, yys, lz(xxs,yys))
light('pos',[-2 0 102])
cameratoolbar show

%%
clf
imagesc(xrange, yrange, lzz); axis xy
% set(vline(x0),'color', 'k', 'linestyle', ':')
xlabel('x [parameter 1]')
ylabel('y [parameter 2]')
title('cost (£)')

% %%
% zz1 = z1(xx);
% surf(xx, yy, zz1)
% 
% %%  Adding them together..
% 
% z = @(x, y) z1(x) + 10*z2(x,y)
% 
% hold off
% imagesc(x, y, log(z(xx,yy)))
% axis xy
% hold on
% xlabel('x [speed parameter]')
% ylabel('y [accuracy parameter]')
% title('£ Cost')
% Plot the optimum
clc
opts = optimset('fminunc');
opts.LargeScale = 'off';
opts.Display = 'none';
pmin = fminunc(@(p) z(p(1), p(2)), [x0 y0], opts);
hold on
plot(pmin(1), pmin(2), 'wo')


cost = z(pmin(1), pmin(2))
text(pmin(1), pmin(2), sprintf('  £%.2f', cost), ...
  'color', 'w', 'hor', 'left')

% Plot the optimum from min(x)
plot(x_init, y_init, 'wo')
cost = z(x_init, y_init)
text(x_init, y_init, sprintf('  £%.2f', cost), ...
  'color', 'w', 'hor', 'left', 'ver', 'bot')

%% Show horizontal slice
hvlinestyles = {'color', [1 1 1]/2, 'linestyle', '-', 'linewidth', 4};
hold on
plot([0 1], [1 1] * y_init, hvlinestyles{:});



%% So, there's an opportunity to make a 20% improvement if
% we can find the optimum.
% What are our options:
%  1. exhaustive search
%  2. random search
%  3. alternation
%  4. simplex
%  5. other derivative-free optimizers
%  6. use derivatives
%  7. use second derivatives

% Problem statement

% Given code to compute function 
%     f (x: real, y:real) -> real
% Find values x,y so that f(x,y) is the smallest possible

% But first look at 1-D problem
%     f (x: real) -> real
% Find value x so that f(x) is the smallest possible

% And we are given a range of x.

%% Rotate to 1D
clf
colormap jet
surfhandle = surf(xxs, yys, lz(xxs,yys));
set(surfhandle, 'edgecolor', [1 1 1]*.25);
% set(vline(x0),'color', 'k', 'linestyle', ':')
xlabel('x [parameter 1]')
ylabel('y [parameter 2]')
title('cost (£)')
view(2)
hold on
x0 = xrange;
y0 = 3;
ls = ones(size(x0));
h = plot3(x0, y0*ls, lz(x0,y0)+4, hvlinestyles{:});
drawnow

% ...
view([0 90])
last = 0;
for k=[0:3:80 81:1:90]
  t = k/90;
  camorbit(0,last-k); last = k;
  axis([0 1 0 7 0 100]);
  set(gca, 'xtick', [0:.25:1]);
  set(gca, 'ytick', [0 7]);
  set(gca, 'ztick', [0 50 100]);
  set(surfhandle, 'facealpha', 1-t.^3)
  set(h, 'zdata', lz(x0,y0)+4-3*t, 'ydata', y0*ls-.1*t);
  drawnow
end


%% xx1 1D problem

clf
z1 = @(x) .8 + (3 - 20*x).^2 .* (.2 + .8*exp(-1e4*x.^2)) + 20*exp(-x*10);
z2 = @(x, y) (y*.5 - 16*x.^2 + 16*x - 5).^2 + y/2
z = @(x,y) z1(x) + 10*z2(x,y)

f = @(x) z(x, 4)
plot(xrange, f(xrange), 'k')
x0 = fminbnd(f, 0, 1)
axis([0 1 0 100])

%
initerrtext = @() text(.6, 20, '', 'tag', 'errt');
initerrtext();
reporterr = @(val, n) set(findobj(gca, 'tag', 'errt'), 'string', ...
  sprintf('error %.1f%%\nsamples %d', (val - 1)*100, n));

%%
% Could try all values, and pick smallest
% for our 1d problem, that gives us a 7% error with 10 samples
hold on
xs = 0:.1:1;
plot(xs, f(xs), 'ko')
reporterr(min(f(xs))/f(x0), length(xs))

%%
% And a .3% error with 50 samples
xs = 0:.02:1;
plot(xs, f(xs), 'ko')
reporterr(min(f(xs))/f(x0), length(xs))

%% But...
fhard = @(x) f(x) - exp(-100*(x-.225).^2).^8*17;
x0 = fminbnd(fhard, 0, 1)
plot(xrange, fhard(xrange), 'r')
xs = 0:.1:1;
plot(xs, fhard(xs), 'ro')
reporterr(min(fhard(xs))./fhard(x0), length(xs))
% 126% error with 10 samples

%%
xs = 0:.01:1;
plot(xs, fhard(xs), 'ro')
reporterr(min(fhard(xs))./fhard(x0), length(xs))
% 2% error with 100 samples

%% Bisection, 1/2 each time
pause on
[xbis, n] = demo_bisection(fhard, .1, .9, .5);
initerrtext();
reporterr(fhard(xbis)./fhard(x0), n)

%% Bisection, golden ratio
pause on
[xbis, n] = demo_bisection(fhard, .1, .9);
initerrtext();
reporterr(fhard(xbis)./fhard(x0), n)

%% Parabolic interp ok

%  Compute parabolic fit and minimum at whiteboard...

[xpar, n] = demo_parabolic(fhard, .1, .9);
errtext = initerrtext();
reporterr(fhard(xpar)./fhard(x0), n)

%% Parabolic interp bad

[xpar, n] = demo_parabolic(fhard, .2, .9);
errtext = initerrtext();
reporterr(fhard(xpar)./fhard(x0), n)

%% 
%  %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
%  %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
%  %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%

%% xx2 And run alternation...
demo_alternation(x0, y0, lz, pmin, 19);

% 19 iterations vs 
% 1000s for dense/random sampling and 
% 100 for a fixed set of linesearches (each y=const)

%% A harder function...
clf
rz0 = @(x,y) z1(x) + 100*(y/2-1 - (4*x - 2).^2).^2;
rz = @(x,y) log(1 + rz0(x,y))

% contour(xx,yy,rz(xx,yy), log(.99+(0:.2:10).^3))
imagesc(xrange,yrange,rz(xx,yy)); axis xy

% use fminunc to generate "ground truth" minimum....
% yes, I'm confident it's within .001%
[gtmin, gtfval] = fminunc(@(p) rz(p(1), p(2)), [x0 y0]);
hold on
plot(gtmin(1), gtmin(2), 'wo', 'markersize', 2, 'linewidth', 2);
plot(gtmin(1), gtmin(2), 'wo', 'markersize', 10, 'linewidth', 2);

%% 3D plot
clf
surfl(xx,yy,rz(xx,yy))

%% And run alternation again...
demo_alternation(x0, y0, rz, gtmin, 200);

%% OK, what can we do better?

% This is a very basic implementation of the Nelder-Meade downhill simplex
% algorithm.  It won't do very well, but has an animation...
clf
imagesc(xrange,yrange,rz(xx,yy)); axis xy
hold on
f = @(p) rz(p(1), p(2));

a = [.1,1]';
b = a + [.1 0]';
c = a + [0 1]';
simplex = [a b c];

colors = { [1 1 1], [1 1 1]/2, [0 0 0] };
for k=1:3
  pthandles(k) = plot(nan,nan, 'o', 'linewidth', 10, 'markersize', 10, 'color', colors{k});
end
th = text;

for iter = 1:20
  fsimplex = [f(simplex(:,1)) f(simplex(:,2)) f(simplex(:,3))];
  [~, i] = sort(fsimplex);
  simplex = simplex(:,i);
  
  plot(simplex(1, [1 2 3 1]), simplex(2, [1 2 3 1]), 'w-', 'linewidth', 3);
  for k=1:3
    setxydata(pthandles(k), simplex(1, k), simplex(2,k));
  end

  if i(end) == length(i)
    % worst was already worst
    simplex(:,2:end) = 1/2*(simplex(:,2:end) + simplex(:,[1 1]));
  else
    % take worst, and project through plane of best
    simplex(:,3) = simplex(:,1) + simplex(:,2) - simplex(:,3);
  end
  err = rz(simplex(1,1), simplex(2,1))/rz(gtmin(1),gtmin(2)); err = (err - 1)*100;
  delete(th);
  th = text(.6, 5, sprintf('Count = %d\nError = %.1f%%', iter, err), 'fontsize', 16);
  pause
end

%%
clf
% contour(xx,yy,rz(xx,yy), log(.99+(0:.2:10).^3))
imagesc(xrange,yrange,rz(xx,yy)); axis xy
hold on
opts = optimset('fminsearch');
opts.Display = 'iter';
[rmin,fval, ~, stats] = fminsearch(f, [.1,1], opts);
err = fval/gtfval; err = (err - 1)*100;
plot(rmin(1), gtmin(2), 'wo', 'markersize', 2, 'linewidth', 2);
plot(rmin(1), gtmin(2), 'wo', 'markersize', 10, 'linewidth', 2);
text(.6, 5, sprintf('fminsearch (Matlab''s Simplex)\nCount = %d\nError = %.1f%%', stats.funcCount, err), 'fontsize', 16);

%%  GRADIENTS
%  %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
%  %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
%  %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%

clf
xrange = -2:.01:2;
yrange = -1:.01:3;
r = @(x,y) 100*(y - x.^2).^2 + (1-x).^2;
drdx = @(x,y) 2*100*(y - x.^2).*(-2*x) - 2.*(1-x);
drdy = @(x,y) 2*100*(y - x.^2);
hold off
imagesc(xrange,yrange,rz(xx,yy)); axis xy
hold on

while 1
  [x,y,button] = ginput(1);
  if button ~= 1, break; end
  hold off
  imagesc(xrange,yrange,rz(xx,yy)); axis xy
  hold on
  gx = drdx(x,y);
  gy = drdy(x,y);
  plot(x,y, 'wo', 'linewidth', 2, 'markersize', 10)
  s = .001;
  h = quiver(x, y, -gx*s*10, -gy*s*10, 0);
  set(h, 'linewidth', 2, 'color', [1 1 1]/2);
  h = quiver(x, y, -gx*s, -gy*s, 0);
  set(h, 'linewidth', 3, 'color', 'w');
end

%% Demo Newton -- back to slides to explain

%% newton on rosenbrock
dnl = demo_taylor_2d(0, 'newton', 'rosenbrock');

%% newton on sqrt rosenbrock
dnl = demo_taylor_2d(0, 'newton', 'sqrt_rosenbrock');

%% dn on rosenbrock
dnl = demo_taylor_2d(0, 'damped newton ls', 'sqrt_rosenbrock');

%% Pick start
dnl = demo_taylor_2d(1, 'damped newton ls', 'sqrt_rosenbrock');


%% Alt vs LM
%log_lm = awf_levmarq_test;

%[~,~,log_alt] = awf_alternation;


%%
clf
plot(log_alt(:,2), 'linewidth', 2)
hold on
plot(log_alt(:,4), log_alt(:,2), 'k', 'linewidth', 2)
plot(log_lm(:,4), log_lm(:,2), 'r', 'linewidth', 2)
plot(dnl.fcalls, dnl.fvals, 'color', [0 1 0]/2, 'linewidth', 2)
set(gca, 'ysc', 'log')
set(gca, 'xsc', 'log')
xlabel('Function evaluations')
ylabel('Energy')
axis([.7 10^6 1e-6 1e5])
legend('Alt (Closed Form)', 'Alt (general)', 'Levenberg Marquardt', 'Damped Newton (general)')
