function obj = acsch(obj)
  obj = log(1 ./ obj + sqrt(1 ./ obj + 1) .* sqrt(1 ./ obj - 1));
end
