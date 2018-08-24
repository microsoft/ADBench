function obj = acosh(obj)
  obj = log(obj + sqrt(obj + 1).*sqrt(obj - 1));
end
