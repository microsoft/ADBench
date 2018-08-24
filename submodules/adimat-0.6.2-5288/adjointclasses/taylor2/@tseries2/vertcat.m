function obj = vertcat(obj, varargin)
  obj = cat(1, obj, varargin{:});
end
