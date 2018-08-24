function obj = pluses(obj, right)
  obj.m_series{1} = obj.m_series{1} + right.m_series{1};
  for k=2:obj.m_ord
    obj.m_series{k} = plusddes(obj.m_series{k}, right.m_series{k});
  end
end
