function demo_taylor_approx(model)

% Demonstrate accuracy of taylor series approximations
if nargin < 1
  model = 'rosenbrock';
end

%%
syms x real

switch model
  case 'rosenbrock'
    t = linspace(-3,3,1001);
    % f =   [10*(y-x.^2)]^2 + [1-x]^2
    f = @(x) 10*(2 - x.^2).^2 + (1-x).^2;
    arange = -2:.1:2;
    ax = [-3,3,-100 500];
  case 'log'
    t = linspace(.001, 4, 100);
    f = @log;
    arange = 0.2:.2:1;
    ax = [0 4 -10 10];
end

for a=arange
  hold off
  h = plot(t,f(t));
  hold on

  plot(a, f(a), 'o');

  colororder = get(gca,'colororder');

  for n=1:3
    T = taylor(f(x), x, 'ExpansionPoint', a, 'order', n+1);
    tvals = subs(T, x, t);
    if length(tvals) == 1
      tvals = tvals * ones(size(t));
    end
    h(end+1) = plot(t,tvals, 'color', colororder(n+1,:));
  end
  axis(ax)

  title(sprintf('Taylor approximations at a = %g', a));
  legend(h, model, 'taylor1','taylor2','taylor3')
  pause
end
