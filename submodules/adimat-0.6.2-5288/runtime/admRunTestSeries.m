function [results sizes alltypes] = admRunTestSeries(handle, initHandle, adopts)
  if nargin < 1
    handle = @adimat_expm;
  end
  if nargin < 2
    initHandle = @(n) {rand(ceil(sqrt(n)))};
  end
  if nargin < 3
    adopts = admOptions();
  end
  
  if ~isfield(adopts, 'x_noplot')
    adopts.x_noplot = [1 1 1];
  end
  
  if length(getenv('DISPLAY')) > 0
    for i=1:length(adopts.x_noplot)
      if ~adopts.x_noplot(i)
        f = figure; bar(1:10);
        adopts.x_axes(i) = get(f, 'currentaxes');
      end
    end
  end

  if isfield(adopts, 'x_ns')
    ns = adopts.x_ns;
  else
    ns = 10.^(0.6:0.2:5);
  end
  
  if isfield(adopts, 'x_tmax')
    tmax = adopts.x_tmax;
  else
    tmax = 3;
  end
  
  % dry run: create all differentiated functions, heat everything
  ndry = ns(1)
  args = initHandle(ndry);
  [times, diffs, alltypes] = admGetTimings(handle, args{:}, adopts);

  bailout = arrayfun(@(x) isnan(x.time), alltypes);
  alltypes = alltypes(~bailout);
  types = alltypes;
  
%  indsc = mat2cell((1:length(types))', ones(length(types), 1))
%  [types.index] = deal(indsc{:});
  
  nruns = 3;
  
  results = nan(length(types), length(ns), nruns);
  sizes = repmat(struct('k', 0, 'm', 0, 'n', 0), [length(ns) 1]);
  
  independents = adopts.independents;
  if isempty(independents)
    independents = 1:length(args);
  end

  % options for speed
  adopts.checknargs = 0;
  adopts.checkoptions = 0;
  adopts.checkResultSizes = 0;
  adopts.forceTransform = -1;
  adopts.nargout = nargout(func2str(handle));
  
  for k=1:length(types)
    for i = 1:length(ns)
      n = ceil(ns(i))
      sizes(i).k = n;
      [args] = initHandle(n);
      [types.k] = deal(n);
      realn(i) = admTotalNumel(args{independents});
      adopts.x_methods = types(k);
      for m=1:nruns+1
        [times, diffs, rtypes] = admGetTimings(handle, args{:}, adopts);
        if m > 1
          results(k, i, m-1) = rtypes.time;
        end
        if rtypes.time > tmax || isnan(rtypes.time)
          break
        end
      end
      sizes(i).m = rtypes.m;
      sizes(i).n = rtypes.n;
      if any(isnan(results(k, i, :)))
        break
      end
    end
  end

end
% $Id: admRunTestSeries.m 4583 2014-06-20 21:20:32Z willkomm $
