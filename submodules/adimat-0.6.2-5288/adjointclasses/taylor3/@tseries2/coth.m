function obj = coth(obj)
  [sh, ch] = sinhcosh(obj);
  obj = ch ./ sh;
end
