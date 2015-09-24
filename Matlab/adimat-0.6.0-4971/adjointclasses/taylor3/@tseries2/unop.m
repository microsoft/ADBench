function obj = unop(obj, handle)
  obj.m_series = cellfun(handle, obj.m_series, 'UniformOutput', false);
end
