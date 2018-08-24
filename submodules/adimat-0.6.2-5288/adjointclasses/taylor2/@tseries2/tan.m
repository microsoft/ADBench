function obj = tan(obj)
  [s, c] = sincos(obj);
  obj = s ./ c;
end
