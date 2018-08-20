function TCs = coeffs(obj, maxOrder, directions)
  nx = numel(obj.m_series{1});
  ndd = admGetNDD(obj.m_series{2});
  if nargin < 2
    maxOrder = obj.m_ord-1;
  end
  if nargin < 3
    directions = 1:ndd;
  end
  TC = zeros(nx, ndd, maxOrder);
  for o=1:maxOrder
    TC(:, :, o) = admJacFor(obj.m_series{o+1});
  end
  if ~isequal(directions, 1:ndd)
    ndd = length(directions);
    TCs(:, 1:ndd, :) = TC(:, directions, :);
  else
    TCs = TC;
  end
