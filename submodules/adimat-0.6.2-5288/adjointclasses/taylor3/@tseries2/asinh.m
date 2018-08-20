function obj = asinh(obj)
  obj = log(obj + sqrt(obj.^2 + 1));
end
