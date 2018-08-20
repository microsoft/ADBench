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
    if meas(1) > 0.5
      if k == 1
        fprintf('%s: ', func2str(handle));
      end
      fprintf('.');
    end
    z = z + r;
  end
  r = handle(args{:});
  ts = [mean(meas) std(meas)];
  if meas(1) > 0.5
    fprintf('\n');
  end
