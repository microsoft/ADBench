function obj = asech(obj)
  obj = log(1 ./ obj + sqrt(1 ./ obj.^2 + 1));
end
