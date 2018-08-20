function obj = roots(obj)
  assert(obj.maxorder = 1);
  [par, x] = partial_roots(obj.m_series{1});
  obj.m_series{1} = x;
  obj.m_series{2} = reshape(par * obj.m_series{2}(:), size(x));
