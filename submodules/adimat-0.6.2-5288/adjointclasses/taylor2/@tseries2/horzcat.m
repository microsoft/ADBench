function obj = horzcat(obj, varargin)
  obj = cat(2, obj, varargin{:});
end
