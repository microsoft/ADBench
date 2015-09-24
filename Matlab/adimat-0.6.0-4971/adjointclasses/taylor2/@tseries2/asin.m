function obj = asin(obj)
  obj = -i .* log( i.*obj + sqrt(1 - obj.^2) );
end
