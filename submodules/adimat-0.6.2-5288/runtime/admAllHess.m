function [Hess, Jacs, results, times, timings, errors] = admAllHess(handle, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions;
    funcArgs = varargin;
  end

  functionName = func2str(handle);
  
  Hess = struct('T1Rev', [], 'T2For', [], 'T2VFor', [], 'T2FD', [], 'FDRev', [], 'CVRev', []);
  Jacs = Hess;
  times = Hess;
  timings = Hess;
  errors = Hess;
  
  if isfield(admOpts, 'x_nTakesTF')
    nTakesTF = admOpts.x_nTakesTF;
  else
    nTakesTF = 3;
  end

  if ~isempty(admOpts.functionResults)
    fNargout = length(admOpts.functionResults);
  elseif ~isempty(admOpts.nargout)
    fNargout = admOpts.nargout;
  else
    fNargout = nargout(functionName);
  end

  results = cell(1, fNargout);
  dresults = cell(1, fNargout);

  timesF = zeros(nTakesTF, 1);
  for i=1:nTakesTF
    tic
    [results{1:fNargout}] = handle(funcArgs{:});
    timesF(i) = toc;
  end
  tF = mean(timesF);
  times.function = tF;

  if isempty(admOpts.functionResults)
    admOpts.functionResults = results;
  end
    
  try
    admOpts.hessianStrategy = 't1rev';
    tic
    [Hess.T1Rev, Jacs.T1Rev, dresults{1:fNargout}, timings.T1Rev] = admHessian(handle, 1, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:T1Rev', '%s', 'admHessian/T1Rev returned wrong results');
    end
    times.T1Rev = toc;
  catch
    le = lasterror;
    warning('adimat:admAllHess:T1Rev', 'admHessian/T1Rev failed: %s', le.message);
    errors.T1Rev = le;
    Hess.T1Rev = [];
    times.T1Rev = [];
  end

  try
    admOpts.hessianStrategy = 't2for';
    admOpts.admDiffFunction = @admTaylorFor;
    tic
    [Hess.T2For, Jacs.T2For, dresults{1:fNargout}, timings.T2For] = admHessian(handle, 1, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:T2For', '%s', 'admHessian/T2For returned wrong results');
    end
    times.T2For = toc;
  catch
    le = lasterror;
    warning('adimat:admAllHess:T2For', 'admHessian/T2For failed: %s', le.message);
    errors.T2For = le;
    Hess.T2For = [];
    times.T2For = [];
  end

  try
    admOpts.hessianStrategy = 't2for';
    admOpts.admDiffFunction = @admTaylorVFor;
    tic
    [Hess.T2VFor, Jacs.T2VFor, dresults{1:fNargout}, timings.T2VFor] = admHessian(handle, 1, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:T2VFor', '%s', 'admHessian/T2VFor returned wrong results');
    end
    times.T2VFor = toc;
  catch
    le = lasterror;
    warning('adimat:admAllHess:T2VFor', 'admHessian/T2VFor failed: %s', le.message);
    errors.T2VFor = le;
    Hess.T2VFor = [];
    times.T2VFor = [];
  end

  try
    admOpts.hessianStrategy = 't2for';
    admOpts.admDiffFunction = @admDiffFD;
    tic
    [Hess.T2FD, Jacs.T2FD, dresults{1:fNargout}, timings.T2FD] = admHessian(handle, 1, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:T2FD', '%s', 'admHessian/T2FD returned wrong results');
    end
    times.T2FD = toc;
  catch
    le = lasterror;
    warning('adimat:admAllHess:T2FD', 'admHessian/T2FD failed: %s', le.message);
    errors.T2FD = le;
    Hess.T2FD = [];
    times.T2FD = [];
  end
  
  try
    admOpts.hessianStrategy = 'fd';
    admOpts.admDiffFunction = @admDiffRev;
    tic
    [Hess.FDRev, Jacs.FDRev, dresults{1:fNargout}, timings.FDRev] = admHessian(handle, 1, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:FDRev', '%s', 'admHessian/FDRev returned wrong results');
    end
    times.FDRev = toc;
  catch
    le = lasterror;
    warning('adimat:admAllHess:FDRev', 'admHessian/FDRev failed: %s', le.message);
    errors.FDRev = le;
    Hess.FDRev = [];
    times.FDRev = [];
  end
  
  try
    admOpts.hessianStrategy = 'cv';
    admOpts.admDiffFunction = @admDiffRev;
    tic
    [Hess.CVRev, Jacs.CVRev, dresults{1:fNargout}, timings.CVRev] = admHessian(handle, 1, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:CVRev', '%s', 'admHessian/CVRev returned wrong results');
    end
    times.CVRev = toc;
  catch
    le = lasterror;
    warning('adimat:admAllHess:CVRev', 'admHessian/CVRev failed: %s', le.message);
    errors.CVRev = le;
    Hess.CVRev = [];
    times.CVRev = [];
  end
  
% $Id: admAllHess.m 4251 2014-05-18 20:25:07Z willkomm $
