function [diffs, Hess, Jacs, results, times, timings, errors] = admAllDiffMatrix(handle, varargin)

  lastArg = varargin{end};
  if isstruct(lastArg) && isfield(lastArg, 'admopts')
    adopts = lastArg;
    funcArgs = varargin(1:end-1);
  else
    adopts = admOptions;
    funcArgs = varargin;
  end

  fName = func2str(handle);

  [Hess, Jacs, results, times, timings, errors] = admAllHess(handle, varargin{:});
  
  methods = fieldnames(Hess);
  n = length(methods);
  
  diffs = zeros(n);
  
  for i=1:n
    for j=1:i-1
      if isequal(size(Hess.(methods{i})), size(Hess.(methods{j})))
        diffs(i,j) = metrik(Hess.(methods{i}), Hess.(methods{j}));
      else
        diffs(i,j) = nan;
      end
    end
  end
  
  for i=1:n
    for j=1:i-1
      if isequal(size(Jacs.(methods{i})), size(Jacs.(methods{j})))
        diffs(j,i) = metrik(Jacs.(methods{i}), Jacs.(methods{j}));
      else
        diffs(j,i) = nan;
      end
    end
  end
  
end

function n = metrik(J1, J2)
  maxn = max(norm(J1), norm(J2));
  n = norm(J1 - J2);
  if maxn > 0
    n = n ./ maxn;
  end
end

% $Id: admAllHessMatrix.m 4251 2014-05-18 20:25:07Z willkomm $
