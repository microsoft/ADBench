function out = demo_taylor_2d(pickstart, METHOD, MODEL, PAUSE)

% Demonstrate damped newton min

if nargin < 1
  pickstart = 0;
end

METHODS = {
  'gradient descent'
  'gradient descent ls'
  'coordinate descent'
  'coordinate descent ls'
  'damped newton'
  'damped newton ls'
  'newton'
  'cg'
};

if nargin < 2
   METHOD = METHODS{7};
end

ok=0;
for k=1:length(METHODS)
    if strcmp(METHOD, METHODS{k})
        ok=ok+1;
    end
end
if ok ~= 1
    error('Bad method');
end

if nargin < 4
    PAUSE = 1;
end
MAXITER = 10000;

%%
if nargin < 3
    MODEL = 'sqrt_rosenbrock';
end
switch MODEL
  case 'rosenbrock'
    [xx,yy] = meshgrid(linspace(-3,3,601), linspace(-2.5,4.5, 601));
    % f =   [10*(y-x.^2)]^2 + [1-x]^2
    f = inline('[10*(y - x.^2)].^2 + (1-x).^2');
    x_start = [-1.9; 2];
  case 'sqrt_rosenbrock'
    [xx,yy] = meshgrid(linspace(-3,3,601), linspace(-2.5,4.5, 601));
    % f =   [10*(y-x.^2)]^2 + [1-x]^2
    f = inline('200*([10*(y - x.^2)].^2 + (1-x).^2 ).^.5');
    x_start = [-1.9; 2];
  case 'gauge'
    [xx,yy] = meshgrid(linspace(-3,3,601), linspace(-2.5,4.5, 601));
    f = inline('200*((x*.3 + .7*y).^2).^.4');
    x_start = [-1.9; 2];
  otherwise
    error('bad model');  
    
end

%% Compute derivatives
syms x y real
dx = diff(f(x,y),x);
dy = diff(f(x,y),y);

mkfn = @(s) inline(vectorize(char(s)), 'x', 'y');

symGradient = [dx dy]';
Gradient_x = mkfn(symGradient(1));
Gradient_y = mkfn(symGradient(2));
Gradient = @(x,y) [Gradient_x(x,y); Gradient_y(x,y)];

dxx = diff(dx, x);
dxy = diff(dx, y);
dyx = diff(dy, x);
dyy = diff(dy, y);

symHessian = [dxx dxy; dyx dyy];
h11 = mkfn(symHessian(1,1));
h12 = mkfn(symHessian(1,2));
h21 = mkfn(symHessian(2,1));
h22 = mkfn(symHessian(2,2));
Hessian = @(x,y) [h11(x,y) h12(x,y); h21(x,y) h22(x,y)];

% Compute solver for coord descent
solve_y = solve(dy, y);
solve_x = solve(dx, x);

%% Compute error surface
z = f(xx,yy);

hold off
colormap(jet(256))
image(xx(1,:), yy(:,1), z.^.5*2+10)
hold on
contour(xx,yy,z,[.1 2 20 100 500 1000 2000],'color', [0 0 0])
axis xy

%% Plot global minimum
plot(1,1,'r+');

out.trajectory = zeros(0, 2);
out.fcalls = [];
out.fvals = [];
handles = [];
lambda = 1;
pure_newton = strcmp(METHOD, 'newton');
if pure_newton
    lambda = 0;
end
fevals = 0;
z_approx = 0*xx;
annot_color = [1 1 1];

for iter = 1:MAXITER
  
  if iter == 1
    if ~pickstart
      %% Starting point, around the corner from global min
      x0 = x_start;
    else
      % User chooses start point
      x0 = ginput(1)';
      if isempty(x0)
        break
      end
    end
  end

  %% delete old handles
  delete(handles); handles = [];

  %% Plot start point
  handles(end+1) = plot(x0(1),x0(2),'wo', 'linewidth', 3);

  % evaluate derivatives at x0
  f0 = f(x0(1),x0(2));
  g = Gradient(x0(1),x0(2));
  H = Hessian(x0(1),x0(2));

  % Convergence if gradient magnitude is zero
  gnorm = norm(g);
  if (gnorm < 1e-10) || (lambda > 1e8)
    disp('converged');
    break
  end

  grad_to_plot = g / gnorm * 10;

  if strfind(METHOD, 'newton')
    % Plot Quadratic approx, delta = [x - x0, y - y0]
    % f = f(x0) + g(x0) delta + 1/2 delta' H delta
    %delta = [x y]' - x0;
    %f_approx = f0 + g'*delta + 0.5*delta'*H*delta;

    QuadForm = H + lambda * eye(2);

    delta = [xx(:)-x0(1) yy(:)-x0(2)];
    z_approx(:) = f0 + delta*g + 0.5*sum((delta * QuadForm ).*delta,2);
    %z_approx = subs(f_approx,{x,y},{xx,yy});
  
    newton_min = f0 - 0.5 * g'*(H\g);
    cvals = newton_min+[0.01 0.1 0.5 1]*(f0-newton_min); %min(z_approx(:)) + [.001 .01 .1]*(max(z_approx(:))-min(z_approx(:)));
    [cc,handles(end+1)] = contour(xx,yy,z_approx, cvals,'color', annot_color);
    set(handles(end), 'linewidth', 2);

    % Newton_min_delta = -H\g;
    damped_Newton_min_delta = -(H + lambda*eye(2))\g;
    plotted_lambda = lambda;
  end
  
  %% Update
  old_x0 = x0;
  switch METHOD
    case 'coordinate descent ls'
      %% Coordinate descent with line search
      dir = [rem(iter,2) rem(iter+1,2)]';
      if dir'*g > 0, dir = -dir; end

      f1d = @(t) ...
        f(x0(1) + t * dir(1), x0(2) + t * dir(2));
      
      [t_new, f_new, flags, output] = fminbnd(f1d, -1, 1);
      fevals = fevals + output.funcCount;

      x_new = x0 + t_new * dir;
      x0 = x_new;
    
    case 'coordinate descent'
      %% Exact coordinate descent
      if rem(iter, 2) == 0
        % solve for y given x
        ty_new = real(double(subs(solve_y, x, x0(1))));
        f_y_new = arrayfun(@(x) f(x, x0(2)), ty_new);
        [fmin, imin] = min(f_y_new);
        x0(2) = ty_new(imin);

      else
        % solve for x given y
        tx_new = real(double(subs(solve_x, y, x0(2))));
        f_x_new = arrayfun(@(x) f(x, x0(2)), tx_new);
        [fmin, imin] = min(f_x_new);
        x0(1) = tx_new(imin);
      end
      plotted_lambda = 0;
      
      dir = x0 - old_x0;
    
    case 'gradient descent'
      %% Gradient descent with tuned stepsize
      dir = -g / lambda;
      x_new = x0 + dir;
      f_new = f(x_new(1),x_new(2));
      plotted_lambda = lambda;
      
      grad_to_plot = -dir;
      
      if f_new < f0
        x0 = x_new;
        lambda = lambda / 1.1;
      else
        lambda = lambda * 10;
      end

    case 'gradient descent ls'
      %% Gradient descent with line search
      dir = -g;

      f1d = @(t) ...
        f(x0(1) + t * dir(1), x0(2) + t * dir(2));
      
      [t_new, f_new, flags, output] = fminbnd(f1d, 0, 10);
      fevals = fevals + output.funcCount;

      plotted_lambda = t_new;

      x_new = x0 + t_new * dir;
      x0 = x_new;

      grad_to_plot = -t_new * dir;
      
    case 'damped newton'
      %% Straight damped Newton
      dir = damped_Newton_min_delta;
      x_new = x0 + dir;
      f_new = f(x_new(1),x_new(2));
      if f_new < f0
        x0 = x_new;
        lambda = lambda / 10;
      else
        lambda = lambda * 10;
      end
      fevals = fevals + 2;  % xx why 2?
    case 'newton'
      %% Straight Newton
      x0 = x0 + damped_Newton_min_delta;
      fevals = fevals + 1;  % xx why 2?
    case 'damped newton ls'
      %% Line search along damped Newton direction
 
      dir = damped_Newton_min_delta;

      f1d = @(t) ...
        f(x0(1) + t * dir(1), x0(2) + t * dir(2));
      
      [t_new, f_new, flags, output] = fminbnd(f1d, 0, 10);
      fevals = fevals + output.funcCount;

      x_new = x0 + t_new * dir;

      % Fix lambda
      lambda = lambda / t_new;
      
      x0 = x_new;
    case 'cg'
      %% [nonlinear] Conjugate gradient
      if iter == 1
        old_g = g;
        dir = [0 0]';
      end

      if 0
        % Polak Ribiere: terrible on Rosenbrock
        beta = -g'*(g - old_g) / (old_g'*old_g);
        beta = max(0, beta); % auto-restart
        dir = -g + beta * dir; % i.e. dir = g + beta*old_dir
      
      else
        % Fletcher-Reeves
        beta = g'*g/(old_g'*old_g);
        dir = -g + beta * dir;
        if beta > 1e7
          disp('reset');
          dir = -g;
        end
        
      end
      
      old_g = g;
      
      % linmin
      f1d = @(t) f(x0(1) + t * dir(1), x0(2) + t * dir(2));
      options = optimset('fminbnd');
      options.TolX = 1e-8;
      [t_new, f_new, flags, output] = fminbnd(f1d, 0, 1, options);
      fevals = fevals + output.funcCount;
      if f_new > f0
        disp('resetting, linesearch min > f0');
        t_new = 0;
        old_g = old_g * 1e30; % ensure direction reset on next iter
      end
      x_new = x0 + t_new * dir;

      % will always improve, so just set x0 = x_new
      x0 = x_new;

    otherwise
      error('bad method [%s]', METHOD);
  end
  if ~PAUSE
    rate = 1;
    if iter > 30, rate = 10; end
    if iter > 100, rate = 50; end
    display = (rem(iter, rate) == 0);
  else
    display = 1;
  end
  if display
    eig_H = eig(H);
    title(sprintf('iter %d, f = %.3f, \\lambda:%.1e\\rightarrow%.1e, |\\nabla f| = %.1e, \\sigma(H) = {%.2f,%.2f}', ...
      iter, f0, plotted_lambda, lambda, gnorm, eig_H(1), eig_H(2)));
    handles(end+1) = quiver(old_x0(1),old_x0(2),-grad_to_plot(1),-grad_to_plot(2),0,'color', annot_color);

    dd = x0 - old_x0;
    handles(end+1) = quiver(old_x0(1),old_x0(2), dd(1),dd(2),0,'color',annot_color);
    %handles(end+1) = plot(x0(1), x0(2), 'g+');
    
    out.trajectory(end+1, :) = x0;
  end
  if PAUSE
    drawnow
    % cmd = '';
    cmd = input([METHOD ': press return or q']);
    if cmd == 'q'
      return
    end
  else
    if display
      drawnow
    end
  end
  
%  out.fcalls(end+1) = fevals;
%  out.fvals(end+1) = f_new;
end
fprintf('iterations %d, fevals %d\n', iter, fevals);
