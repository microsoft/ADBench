function obj = repmat(obj, varargin)
  obj.m_series = cellfun(@(x) repmat(x, varargin{:}), obj.m_series, 'UniformOutput', false);
end
