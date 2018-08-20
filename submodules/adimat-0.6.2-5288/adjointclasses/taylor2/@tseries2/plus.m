function obj = plus(obj, right)
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      obj.m_series = cellfun(@plus, obj.m_series, right.m_series, 'UniformOutput', false);
    else
      if isscalar(obj) && ~isscalar(right)
        obj = repmat(obj, size(right));
      end
      obj.m_series{1} = obj.m_series{1} + right;
    end
  else
    val = obj;
    obj = right;
    if isscalar(obj) && ~isscalar(val)
      obj = repmat(obj, size(val));
    end
    obj.m_series{1} = val + obj.m_series{1};
  end
end
