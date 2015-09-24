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
    admOpts.x_bench_full = false;
  end
  if ~isfield(admOpts, 'x_bench_full_est')
    admOpts.x_bench_full_est = false;
  end

  [ts(1,1:2)] = benchmark(@admDiffFor, [{handle, vf}, funcArgs, {admOpts}], L);
  [ts(2,1:2)] = benchmark(@admDiffRev, [{handle, vr}, funcArgs, {admOpts}], L);

  if admOpts.x_bench_10
    [ts(end+1,1:2)] = benchmark(@admDiffFor, [{handle, repmat(vf, [1 10])}, funcArgs, {admOpts}], L)./10;
    [ts(end+1,1:2)] = benchmark(@admDiffRev, [{handle, repmat(vr, [10 1])}, funcArgs, {admOpts}], L)./10;
  end
  
  if admOpts.x_bench_full
    [ts(end+1,1:2)] = benchmark(@admDiffFor, [{handle, 1}, funcArgs, {admOpts}], L);
    [ts(end+1,1:2)] = benchmark(@admDiffRev, [{handle, 1}, funcArgs, {admOpts}], L);
  elseif admOpts.x_bench_full_est && admOpts.x_bench_10
    [ts(end+1,1:2)] = [ts(end-3,1:2)] .* nddf;
    [ts(end+1,1:2)] = [ts(end-3,1:2)] .* nddr;
  end
  
  varargout{1} = [ts(:,1)./trefs(1) ts(:,1) ts(:,2)];
