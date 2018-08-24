function errors = errors(obj, h)
  TCs_top = admJacFor(obj.m_series{obj.m_ord})
  errors = bsxfun(@times, abs(TCs_top), h(:).^(obj.m_ord-1));
