function log_data = demo_alternation(x0, y0, lz, pmin, maxiter)
hvlinestyles = {'color', [1 1 1]*0, 'linestyle', '-', 'linewidth', 4};
x = 0:.01:1;
y = 0:.07:7;
[xx,yy] = meshgrid(x,y);
xk = x0;
yk = y0;
log_data = [];
hline = @(y) plot([min(x) max(x)], [y y]);
vline = @(x) plot([x x], [min(y) max(y)]);

for iter = 1:maxiter
  clf
  colormap jet
  imagesc(x, y, lz(xx,yy)); axis xy
  hold on
  err = lz(xk,yk)/lz(pmin(1),pmin(2)); err = (err - 1)*100;
  th = text(.6, 5, sprintf('Count = %d\nError = %.1f%%', iter-1, err), 'fontsize', 16);
  plot(xk,yk,'wo', 'linewidth', 4);
  
  if (iter < 10) % || (iter < 40 && (rem(iter, 10) == 0))
    rest = @() pause;
  else
    rest = @() drawnow;
  end

  if rem(iter, 2)
    set(hline(yk), hvlinestyles{:});
    xkp1 = fminbnd(@(x) lz(x, yk), 0, 1);
    rest();
    plot(xkp1, yk, 'wo', 'linewidth', 4)
    xk = xkp1;
  else
    set(vline(xk), hvlinestyles{:});
    ykp1 = fminbnd(@(y) lz(xk, y), 0, 7);
    rest();
    plot(xk, ykp1, 'wo', 'linewidth', 4);
    yk = ykp1;
  end
  log_data = [log_data; lz(xk,yk)];
  err = lz(xk,yk)/lz(pmin(1),pmin(2)); err = (err - 1)*100;
  delete(th);
  text(.6, 5, sprintf('Count = %d\nError = %.1f%%', iter, err), 'fontsize', 16);
  %rest();
end
