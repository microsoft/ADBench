function obj = unopV(obj, handle, varargin)
  for k=1:obj.m_ord
    obj.m_series{k} = handle(obj.m_series{k}, varargin{:});
  end
end
