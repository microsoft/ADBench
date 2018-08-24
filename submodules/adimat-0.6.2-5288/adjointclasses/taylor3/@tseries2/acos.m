function obj = acos(obj)
  obj = -i .* log( obj + i.*sqrt(1 - obj.^2) );
end
