function obj = sech(obj)
  [~, obj] = sinhcosh(obj);
  obj = 1 ./ obj;
end
