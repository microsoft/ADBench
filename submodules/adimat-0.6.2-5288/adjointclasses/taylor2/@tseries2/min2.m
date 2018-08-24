function [obj] = min2(obj, right)
  if isscalar(obj)
    szr = size(right);
    obj = repmat(obj, szr);
  end
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      ll = obj.m_series{1} > right.m_series{1};
      for i=1:obj.m_ord
        obj.m_series{i}(ll) = right.m_series{i}(ll);
      end
    else
      ll = obj.m_series{1} > right;
      obj.m_series{1}(ll) = right;
      for i=2:obj.m_ord
        obj.m_series{i}(ll) = 0;
      end
    end
  else
    ll = obj > right.m_series{1};
    obj = tseries2(obj);
    for i=1:obj.m_ord
      obj.m_series{i}(ll) = right.m_series{i}(ll);
    end
  end
end
