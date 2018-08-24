function obj = csch(obj)
  [obj] = sinhcosh(obj);
  obj = 1 ./ obj;
end
