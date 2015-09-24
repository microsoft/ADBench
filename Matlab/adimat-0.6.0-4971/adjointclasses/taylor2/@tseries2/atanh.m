function obj = atanh(obj)
  obj = 0.5 .* log((1 + obj) ./ (1 - obj));
end
