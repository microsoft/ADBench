function z = eval(obj, h, maxorder)
  if nargin < 3
    maxorder = obj.m_ord-1;
  end
  TCs = coeffs(obj, maxorder);
  nx = numel(obj.m_series{1});
  terms = bsxfun(@times, reshape(TCs, nx, []), h.^(1:maxorder));
  z = obj.m_series{1} + reshape(sum(terms, 2), size(obj.m_series{1}));
