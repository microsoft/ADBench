function obj = acoth(obj)
  obj = 0.5 .* log((obj + 1) ./ (obj - 1));
end
