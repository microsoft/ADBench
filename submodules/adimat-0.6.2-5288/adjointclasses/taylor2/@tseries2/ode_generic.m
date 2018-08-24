% function [t, y_obj] = ode_generic(integrator, func, ts, y0)
%
% Copyright (c) 2018 Johannes Willkomm <johannes@johannes-willkomm.de>
%
function [t, y_obj] = ode_generic(integrator, func, ts, y0)
  if y0.m_ord > 2
    error('adimat:tseries2:det:unsupportedOrder', ...
          ['Taylor coefficients of the functions odeXYZ (ode23, ode15s, etc.) are only supported ' ...
           'up to first order, but the maximum order is set to %d'], ...
          obj.m_ord -1);
  end
  % get info about ODE function
  r = functions(func);
  % backup global ndd variable
  curndd = admGetNDD;
  % parse lambda function handle
  [token] = regexp(r.function, '@\((\w+),\W*(\w+)\)\W*(\w+)\W*\((\w+),\W*(\w+),\W*(\w+)\)', 'tokens');
  token = token{1};
  arg_t = token{4};
  arg_y = token{5};
  name_f = token{3};
  arg_p = token{6};
  % get the ode function handle
  fode = str2func(name_f);
  % get the parameter p
  if ~iscell(r.workspace)
    r.workspace = {r.workspace};
  end
  p = r.workspace{1}.(arg_p);
  p_double = p.m_series{1};
  y0_double = y0.m_series{1};
  % run once to get the ode function differentiated, preparing for
  % following runs with nochecks=1
  dfdydp = admDiffFor(fode, 1, ts, y0_double, p_double, admOptions('i', [2,3]));
  g_fode = str2func(['g_' name_f]);
  % construct augmented ODE system
  useDriver = false;
  aug_ode = mkaugode(g_fode, fode, ts, y0_double, p_double, useDriver);
  % initial value
  augy0 = [ y0_double(:); zeros(numel(y0) .* numel(p), 1); reshape(eye(numel(y0)),[],1) ];
  % when using manual invocation of differentiated code, set
  % derivative class to scalar mode
  if ~useDriver
    adimat_derivclass scalar_directderivs
  end
  % and run integrator
  [t, y] = integrator(@(t,y) aug_ode(t,y,p_double), ts, augy0);
  % reset global ndd variable, and derivative class, which was modified
  % by the admTaylorFor calls in aug_ode
  adimat_derivclass arrderivclass
  set(g_dummy, 'ndd', curndd);
  nt = numel(t);
  ny = numel(y0);
  np = numel(p);
  y_orig = y(:,1:ny);
  y_obj = tseries2(y_orig);
  dydp  = reshape(y(:,ny+1:ny+ny*np),[nt.*ny, np]);
  dydy0 = reshape(y(:,ny+ny*np+1:end),[nt.*ny, ny]);
  dp = dydp * p.m_series{2}(:);
  dy0 = dydy0 * y0.m_series{2}(:);
  y_obj.m_series{2} = reshape(dp + dy0, size(y_orig));
end
function aug_ode = mkaugode(g_fode, fode, ts, y0, p, useDriver)
  fode_yp = mktaydiff_yp(g_fode, fode, ts, y0, p, useDriver);
  function [dy_new] = augode_(t_, y_, p_)
      ny = numel(y0);
      np = numel(p);
      y_orig = y_(1:ny);
      dydp = y_(ny+1:ny+np*ny);
      dydp = reshape(dydp,ny,np);
      dydy0 = y_(ny+np*ny+1:end);
      dydy0 = reshape(dydy0,ny,ny);
      dy = fode(t_, y_orig, p_);
      [dfdy, dfdp] = fode_yp(t_, y_orig, p_);
      ddydp = dfdy * dydp + dfdp;
      ddydy0 = dfdy * dydy0;
      dy_new = [ dy(:); ddydp(:); ddydy0(:) ];
  end
  aug_ode = @augode_;
end
function f_ode_py = mktaydiff_yp(g_fode, fode, ts, y0, p, useDriver)
  function [dfdy, dfdp] = f_ode_py_(t_, y_, p_)
    %    dfdyp = admTaylorFor(fode, 1, t_, y_, p_, admOptions('i', [2,3], 'nochecks', 1));
    %    dfdyp = admDiffFor(fode, 1, t_, y_, p_, admOptions('i', [2,3], 'nochecks', 1));
    ny = numel(y_);
    np = numel(p_);
    if useDriver
      [J, dy] = admDiffFor(fode, 1, t_, y_, p_, admOptions('i', [2,3], 'nochecks', 1));
      dfdy = dy(:,1:ny);
      dfdp = dy(:,ny+1:end);
    else
      dfdy = zeros(ny, ny);
      dfdp = zeros(ny, np);
      g_y = zeros(ny, 1);
      g_p = zeros(np, 1);
      for k=1:ny
        g_y(k) = 1;
        [g_dy, dy] = g_fode(t_, g_y, y_, g_p, p_);
        dfdy(:,k) = g_dy;
        g_y = zeros(ny, 1);
      end
      for k=1:np
        g_p(k) = 1;
        [g_dy, dy] = g_fode(t_, g_y, y_, g_p, p_);
        dfdp(:,k) = g_dy;
        g_p = zeros(np, 1);
      end
    end
  end
  f_ode_py = @f_ode_py_;
end
