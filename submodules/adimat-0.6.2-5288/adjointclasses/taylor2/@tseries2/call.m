function obj = call(handle, obj)
  obj.m_series{1} = handle(obj.m_series{1});
  obj.m_series(2:end) = cellfun(@(x) call(handle, x), obj.m_series(2:end), 'UniformOutput', false);
end
