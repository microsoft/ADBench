function obj = reshape(obj, varargin)
  obj.m_series = cellfun(@(x) reshape(x, varargin{:}), obj.m_series, ...
                         'UniformOutput', false);
end
