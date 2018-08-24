function obj = min(obj, right)
  if nargin == 1
    [obj, mi] = min1(obj);
  elseif nargin == 2
    [obj] = min2(obj, right);
  end
end
