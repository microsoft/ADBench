function obj = dot(obj, right, varargin)
  obj = sum(obj .* right, varargin{:});
