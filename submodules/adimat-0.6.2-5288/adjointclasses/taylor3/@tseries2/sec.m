function obj = sec(obj)
  [~, obj] = sincos(obj);
  obj = 1 ./ obj;
end
