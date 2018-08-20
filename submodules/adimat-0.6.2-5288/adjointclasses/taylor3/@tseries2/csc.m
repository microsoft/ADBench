function obj = csc(obj)
  [obj] = sincos(obj);
  obj = 1 ./ obj;
end
