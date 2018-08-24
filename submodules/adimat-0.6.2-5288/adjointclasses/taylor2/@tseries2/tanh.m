function obj = tanh(obj)
  [sh, ch] = sinhcosh(obj);
  obj = sh ./ ch;
end
