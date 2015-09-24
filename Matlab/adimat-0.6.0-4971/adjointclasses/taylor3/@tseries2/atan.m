function obj = atan(obj)
  obj = 0.5 .* i .* log( (1 - i.*obj) ./ (1 + i.*obj) );
end
