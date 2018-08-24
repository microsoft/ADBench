function [diffs, Jacs, results, times, timings, errors] = admAllDiffMatrix(handle, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    adopts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    adopts = admOptions;
    funcArgs = varargin;
  end

  fName = func2str(handle);

  [Jacs{1:6}, results, times, errors] = admAllDiff(handle, varargin{:});

  if isfield(adopts, 'x_metric')
    metric = admGetFunc(adopts.x_metric);
  else
    metric = @(x, y) relMaxNorm(x, y, 1);
  end
  
  if isfield(adopts, 'x_truth')
    truth = adopts.x_truth;
  else
    truth = [];
  end

  diffs = admDiffMatrix(Jacs, metric, truth);

end

% $Id: admAllDiffMatrix.m 4996 2015-05-17 21:13:06Z willkomm $
