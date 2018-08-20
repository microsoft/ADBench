function [JFor, JVFor, JRev, JFD, JComplex, JTayFor, results, times, errors] = admAllDiff(handle, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    admOpts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    admOpts = admOptions;
    funcArgs = varargin;
  end

  functionName = func2str(handle);
  
  times = struct();
  errors = struct();
  
  if isfield(admOpts, 'x_nTakesTF')
    nTakesTF = admOpts.x_nTakesTF;
  else
    nTakesTF = 3;
  end

  if isfield(admOpts, 'x_seedFor')
    seedFor = admOpts.x_seedFor;
  else
    seedFor = 1;
  end

  if isfield(admOpts, 'x_seedRev')
    seedRev = admOpts.x_seedRev;
  else
    seedRev = 1;
  end

  if isfield(admOpts, 'x_modes')
    modes = admOpts.x_modes;
  else
    modes = 'Fftrdc';
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

  clear(func2str(handle));
  
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
  
  if strfind(modes, 'F')
  try
    tic
    [JFor, dresults{1:fNargout}] = admDiffFor(handle, seedFor, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      warning('adimat:admAllDiff:results:For', '%s', 'admDiffFor returned wrong results');
      for i=1:fNargout
        warning('adimat:admAllDiff:results:For', 'Error in result %d: %g', ...
                i, relMaxNorm(dresults{i},  results{i}));
      end
    end
    times.For = toc;
  catch
    le = lasterror;
    warning('adimat:admAllDiff:JFor', 'admDiffFor failed: %s', le.message);
    errors.JFor = le;
    JFor = [];
    times.For = [];
  end
  else
    JFor = [];
  end
  
  if strfind(modes, 'f')
  try
    tic
    [JVFor, dresults{1:fNargout}] = admDiffVFor(handle, seedFor, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      warning('adimat:admAllDiff:results:VFor', '%s', 'admDiffVFor returned wrong results');
      for i=1:fNargout
        warning('adimat:admAllDiff:results:VFor', 'Error in result %d: %g', ...
                i, relMaxNorm(dresults{i},  results{i}));
      end
    end
    times.VFor = toc;
  catch
    le = lasterror;
    warning('adimat:admAllDiff:JVFor', 'admDiffVFor failed: %s', le.message);
    errors.JVFor = le;
    JVFor = [];
    times.VFor = [];
  end
  else
    JVFor = [];
  end
  
  if strfind(modes, 't')
  try
    tic
    [JTayFor, dresults{1:fNargout}] = admTaylorFor(handle, seedFor, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      warning('adimat:admAllDiff:results:TayFor', '%s', 'admTaylorFor returned wrong results');
      for i=1:fNargout
        warning('adimat:admAllDiff:results:TayFor', 'Error in result %d: %g', ...
                i, relMaxNorm(dresults{i},  results{i}));
      end
    end
    times.TayFor = toc;
  catch
    le = lasterror;
    warning('adimat:admAllDiff:JTayFor', 'admTaylorFor failed: %s', le.message);
    errors.JTayFor = le;
    JTayFor = [];
    times.TayFor = [];
  end
  else
    JTayFor = [];
  end
  
  if strfind(modes, 'r')
  try
    tic
    [JRev, dresults{1:fNargout}] = admDiffRev(handle, seedRev, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      warning('adimat:admAllDiff:results:Rev', '%s', 'admDiffRev returned wrong results');
      for i=1:fNargout
        warning('adimat:admAllDiff:results:Rev', 'Error in result %d: %g', ...
                i, relMaxNorm(dresults{i},  results{i}));
      end
    end
    times.Rev = toc;
  catch
    le = lasterror;
    warning('adimat:admAllDiff:JRev', 'admDiffRev failed: %s', le.message);
    errors.JRev = le;
    JRev = [];
    times.Rev = [];
  end
  else
    JRev = [];
  end

  if strfind(modes, 'd')
  try
    tic
    [JFD, dresults{1:fNargout}] = admDiffFD(handle, seedFor, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:FD', '%s', 'admDiffFD returned wrong results');
      for i=1:fNargout
        warning('adimat:admAllDiff:results:FD', 'Error in result %d: %g', ...
                i, relMaxNorm(dresults{i},  results{i}));
      end
    end
    times.FD = toc;
  catch
    le = lasterror;
    warning('adimat:admAllDiff:JFD', 'admDiffFD failed: %s', le.message);
    errors.JFor = le;
    JFD = [];
    times.FD = [];
  end
  else
    JFD = [];
  end
  
  if strfind(modes, 'c')
  try
    tic
    [JComplex, dresults{1:fNargout}] = admDiffComplex(handle, seedFor, funcArgs{:}, admOpts);
    if ~isequal(results, dresults)
      error('adimat:admAllDiff:results:Complex', '%s', 'admDiffComplex returned wrong results');
    end
    times.Complex = toc;
  catch
    le = lasterror;
    warning('adimat:admAllDiff:JComplex', 'admDiffComplex failed: %s', le.message);
    errors.JComplex = le;
    JComplex = [];
    times.Complex = [];
  end
  else
    JComplex = [];
  end

  JFor = seedRev * JFor;
  JVFor = seedRev * JVFor;
  JTayFor = seedRev * JTayFor;
  JFD = seedRev * JFD;
  JComplex = seedRev * JComplex;

  JRev = JRev * seedFor;

% $Id: admAllDiff.m 5107 2016-05-29 21:59:23Z willkomm $
