function TCs = coeffs(obj, maxOrder)
  if nargin < 2
    maxOrder = obj.m_ord-1;
  end
  nx = numel(obj.m_series{1});
  TCs = zeros(nx, maxOrder);
  for o=1:maxOrder
    TCs(:, o) = obj.m_series{o+1}(:);
  end
  TCs = reshape(TCs, [size(obj.m_series{1}) maxOrder]);
