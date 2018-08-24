function z = eval(obj, h, maxorder, directions)
  nx = numel(obj.m_series{1});
  ndd = admGetNDD(obj.m_series{2});
  if nargin < 3
    maxorder = obj.m_ord-1;
  end
  if nargin < 4
    directions = 1:ndd;
  end
  TCs = coeffs(obj, maxorder, directions);
  hpowers = bsxfun(@power, h(:), 1:maxorder);
  terms = bsxfun(@times, TCs, reshape(hpowers, [1 length(directions) maxorder]));
  z = obj.m_series{1} + reshape(sum(sum(terms, 3),2), size(obj.m_series{1}));
