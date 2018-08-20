function obj = cot(obj)
  [s, c] = sincos(obj);
  obj = c ./ s;
end
