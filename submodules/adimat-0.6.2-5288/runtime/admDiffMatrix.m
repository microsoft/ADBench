function [diffs] = admDiffMatrix(items, metric, truth)

  if nargin < 2
    metric = @(x, y) relMaxNorm(x, y, 1);
  end
  if nargin < 3
    truth = [];
  end
  
  N = length(items);
  diffs = zeros(N);
  
  for i=1:N
    for j=1:i-1
      if isequal(size(items{i}), size(items{j}))
        diffs(i,j) = metric(items{i}, items{j});
      else
        diffs(i,j) = nan;
      end
    end
    if ~isempty(truth)
      diffs(i,N+1) = metric(items{i}, truth);
    end
  end
  
end

% $Id: admDiffMatrix.m 4165 2014-05-13 08:27:37Z willkomm $
