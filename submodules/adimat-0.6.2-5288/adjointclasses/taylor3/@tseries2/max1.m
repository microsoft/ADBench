function [obj, mi] = max1(obj)
  [mv, mi] = max(obj.m_series{1});
  for i=1:obj.m_ord
    obj.m_series{i} = obj.m_series{i}(mi);
  end
end
