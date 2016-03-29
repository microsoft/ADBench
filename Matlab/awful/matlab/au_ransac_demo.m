function au_ransac_demo
%  AU_RANSAC_DEMO  Example of use of au_ransac

% awf, aug06

N=200;
NoiseSigma = 0.05;
x = rand(N,1);
y = 1.5 * x + 1  + randn(N,1) * NoiseSigma;;
THRESH = 2*NoiseSigma;

ind = find(rand(N,1) < 0.8);
y(ind) = rand(size(ind)) * 3;

clf
hold off
plot([0 1], [1 2.5], 'color', [0 0 0], 'linewidth', 1);
hold on
plot([0 1], [1 2.5]-THRESH, 'color', [1 1 1]*.7, 'linewidth', 1);
plot([0 1], [1 2.5]+THRESH, 'color', [1 1 1]*.7, 'linewidth', 1);
plot(x,y,'.')
axis([0 1 0 3]);

polyorder = 3;

% Function to return parameters given data indices
f_fit = @(indices) ...
  polyfit(x(indices), y(indices), polyorder);

% Function to compute residuals for given data indices and params
f_compute_residuals = @(params,indices) ...
  abs(polyval(params, x(indices)) - y(indices)) > THRESH;

% Verbose output function
xrange = linspace(0,1,100);
draw_handle_1 = plot([0 1], [nan nan], 'r');
draw_handle_2 = plot(nan, nan, 'ro');
f_out = @(tag, indices, params) ...
  [setxy(draw_handle_1, xrange, polyval(params, xrange))
   setxy(draw_handle_2, x(indices), y(indices))];

opts = au_ransac('opts');
opts.NDATA = N;
opts.NSAMPLES = polyorder + 1;
opts.fit = f_fit;
opts.compute_residuals = f_compute_residuals;
opts.output = f_out;
params = au_ransac(opts);
disp(params);

function h = setxy(h, x, y)
set(h, 'xdata', x, 'ydata', y);
drawnow

