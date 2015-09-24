function obj = binop(obj, right, handle)
  if isa(obj, 'tseries2')
    if isa(right, 'tseries2')
      obj.m_series = cellfun(handle, obj.m_series, right.m_series, 'UniformOutput', false);
    else
      obj.m_series = cellfun(@(x) handle(x, right), obj.m_series, 'UniformOutput', false);
    end
  else
    val = obj;
    obj = right;
    obj.m_series = cellfun(@(y) handle(val, y), right.m_series, 'UniformOutput', false);
  end
end
