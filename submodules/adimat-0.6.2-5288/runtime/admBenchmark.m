function varargout = admBenchmark(handle, args, L)
  if nargin < 3
    L = 5;
  end

  lastArg = args{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = args(1:end-1);
  else
    admOpts = admOptions();
    funcArgs = args;
  end

  functionName = func2str(handle);

  if isempty(admOpts.nargout)
    fNargout = nargout(functionName);
  else
    fNargout = admOpts.nargout;
  end

  nFuncArgs = length(funcArgs);
  independents = admOpts.independents;
  if isempty(independents)
    independents = 1:nFuncArgs;
  end
  nActArgs = length(independents);

  dependents = admOpts.dependents;
  if isempty(dependents)
    dependents = 1:fNargout;
  end
  nActResults = length(dependents);
  
  
  [results{1:fNargout}] = handle(funcArgs{:});
  admOpts.functionResults = results;
  admOpts.nargout = fNargout;
    
  trefs = benchmark(handle, funcArgs);
  
  fprintf('Function took %g (+/- %g) s to evaluate\n', trefs(1), trefs(2));
  if trefs(1) > 0.01
    if ~isfield(admOpts, 'x_bench_full') && ~isfield(admOpts, 'x_bench_full_est')
      warning('set default options: test run with small NDD (10) only, estimate full jacobian');
      admOpts.x_bench_10 = true;
      admOpts.x_bench_full_est = true;
    end
  end

  if isfield(admOpts, 'x_bench_10') && admOpts.x_bench_10 && ~isfield(admOpts, 'x_bench_full_est')
    admOpts.x_bench_full_est = true;
  end
  
  nddf = admTotalNumel(funcArgs(independents));
  nddr = admTotalNumel(results(dependents));

  vf = rand(nddf, 1);
  vr = rand(1, nddr);
  
  % dummy runs
  JF = admDiffFor(handle, vf, funcArgs{:}, admOpts);
  JR = admDiffRev(handle, vr, funcArgs{:}, admOpts);
  
  assert(relMaxNorm(vr * JF, JR * vf) < 1e-12);

  admOpts.nochecks = 1;

  if ~isfield(admOpts, 'x_bench_10')
    admOpts.x_bench_10 = true;
  end
  if ~isfield(admOpts, 'x_bench_full')
    admOpts.x_bench_full = true;
  end
  if ~isfield(admOpts, 'x_bench_full_est')
    admOpts.x_bench_full_est = true;
  end
  if ~isfield(admOpts, 'x_bench_k')
    admOpts.x_bench_k = 10000;
  end

  [ts(1,1:2)] = trefs;

  [ts(end+1,1:2)] = benchmark(@admDiffFor, [{handle, vf}, funcArgs, {admOpts}], L);
  [ts(end+1,1:2)] = benchmark(@admDiffRev, [{handle, vr}, funcArgs, {admOpts}], L);

  optCols = {};
  if admOpts.x_bench_10
    [ts(end+1,1:2)] = benchmark(@admDiffFor, [{handle, repmat(vf, [1 admOpts.x_bench_k])}, funcArgs, {admOpts}], L)./admOpts.x_bench_k;
    [ts(end+1,1:2)] = benchmark(@admDiffRev, [{handle, repmat(vr, [admOpts.x_bench_k 1])}, funcArgs, {admOpts}], L)./admOpts.x_bench_k;
    optCols = [ optCols {sprintf('FM J * (%d x %d)/%d', nddf, admOpts.x_bench_k, ...
                                 admOpts.x_bench_k), sprintf('RM (%d x %d) * J/%d', admOpts.x_bench_k, ...
                                                      nddr, admOpts.x_bench_k)}];
  end
  
  if admOpts.x_bench_full
    ts1 = benchmark(@admDiffFor, [{handle, 1}, funcArgs, {admOpts}], L);
    ts2 = benchmark(@admDiffRev, [{handle, 1}, funcArgs, {admOpts}], L);
    ts(end+1,1:2) = ts1 ./ nddf;
    ts(end+1,1:2) = ts2 ./ nddr;
    [ts(end+1,1:2)] = ts1;
    [ts(end+1,1:2)] = ts2;
    optCols = [ optCols {sprintf('FM J/%d', nddf), sprintf('RM J/%d', nddr), 'FM J', 'RM J', }];
  end
  if admOpts.x_bench_full_est && admOpts.x_bench_10
    ts(end+1,1:2) = ts(4,1:2).* nddf;
    ts(end+1,1:2) = ts(5,1:2).* nddr;
    optCols = [ optCols {'FM J (est.)', 'RM J (est.)'}];
  end
  
  ts(:,3) = 100 .* ts(:,2) ./ ts(:,1);
  
  varargout{1} = [ts(:,1)./trefs(1) ts(:,1) ts(:,2)];

  if exist('table')
    varargout{1} = table(ts(:,1)./trefs(1), ts(:,1), ts(:,2), ts(:,3), ...
                         'VariableNames', {'relTime', 'absTime', 'stdTime', 'stdTimeRel'}, ...
                         'RowNames', {'f', 'FM J*v', 'RM w*J', optCols{:}});
  end
