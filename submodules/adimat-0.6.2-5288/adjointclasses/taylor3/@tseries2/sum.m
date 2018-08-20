function obj = sum(obj, varargin)
  obj = unopV(obj, @sum, varargin{:});
end
