function [ts meas] = benchmark(handle, args, L)
  if nargin < 3
    L = 5;
  end
  meas = zeros(L, 1);
  r = handle(args{:});
  z = 0;
  for k=1:L
    tic
    r = handle(args{:});
    meas(k) = toc;
    z = z + r;
  end
  r = handle(args{:});
  ts = [mean(meas) std(meas)];
