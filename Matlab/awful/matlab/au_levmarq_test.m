function logout = au_levmarq_test

% au_levmarq_test Unit test for au_levmarq

% Constant in Rosenbrock function
K = 10;

% Starting point, around the corner from global min
x=[-1.9, 2];

%% Set GX = 0 to do without the graphical display
GX = 1;
if GX
  disp('plotting')
  %% plot function
  range = linspace(-4,4,97);
  [xx,yy] = meshgrid(range);
  zz = xx;
  for i=1:numel(xx)
    e = au_rosenbrock([xx(i) yy(i)], K);
    zz(i) = sum(e.^2);
  end
  clf
  contour(xx,yy,zz,2.^[-1 2 4 6:18])
  hold on
  axis xy
  drawnow
  % GX.ax = get(h,'parent');
end

% define optimization function
f = @(x) au_rosenbrock(x, K);

% check it at some values
%[e,J] = f(x);
%f([1,1]);

% call LM
opts = au_levmarq('opts');
opts.Display = 'iter';
if GX
  opts.IterStartFcn = @(x) plot_fun(x);
end
opts.USE_LINMIN = 1;
au_levmarq(x, f, opts);

opts.IterStartFcn = [];

opts.Display = 'final+';
au_levmarq(x, f, opts);

opts.Display = 'final';
au_levmarq(x, f, opts);

opts.Display = 'none';
tic
opts.USE_LINMIN = 1;
au_levmarq(x, f, opts);
fprintf('Time with linmin %g sec\n', toc);
tic
opts.USE_LINMIN = 0;
au_levmarq(x, f, opts);
fprintf('Time without linmin %g sec (should be much faster as J is tiny)\n', toc);

function x = plot_fun(x)
h = plot(x(1),x(2), 'b.');
% set(h,'marker', 'o', 'markersize', 10, 'color', 'r');
drawnow
