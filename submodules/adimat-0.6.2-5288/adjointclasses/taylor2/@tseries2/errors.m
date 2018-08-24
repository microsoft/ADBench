function errors = errors(obj, h)
  TCs_top = obj.m_series{obj.m_ord};
  errors = abs(TCs_top) .* h.^(obj.m_ord-1);
