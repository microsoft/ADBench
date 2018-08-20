function obj = unopc(obj, handle, varargin)
  obj.m_series{1} = handle(obj.m_series{1}, varargin{:});
  obj.m_series(2:end) = cellfun(@(x) call(handle, x, varargin{:}), obj.m_series(2:end), 'UniformOutput', false);
end
